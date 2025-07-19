//
//  WorkoutViewModel.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import SwiftUI
import Combine
import Foundation
import AudioToolbox

class WorkoutViewModel: ObservableObject {
    @Published var activeDays: [WorkoutDay] = WorkoutDay.allCases
    
    // Almacena las DEFINICIONES ÚNICAS de los ejercicios
    @Published var availableExercises: [Exercise] = []
    
    // Almacena el progreso diario. Cada WorkoutExercise se refiere a un Exercise por su ID
    @Published var dailyWorkoutRecords: [WorkoutDay: [WorkoutExercise]] = [:]
    
    @Published var workoutHistory: [Date: [WorkoutDay: [WorkoutExercise]]] = [:]
    @Published var bodyWeightHistory: [Date: Double] = [:]
    @Published var timerActive = false
    @Published var timeRemaining = 120
    @Published var currentTimerDuration: Int = 120 // Duración del timer actual
    @Published var isTimerEnabled = true // Estado del timer desde ThemeManager
    @Published var restDuration: Int = 120 { // Tiempo de descanso personalizable (por defecto 2 minutos)
        didSet {
            UserDefaults.standard.set(restDuration, forKey: "RestDuration")
            print("WorkoutViewModel: restDuration actualizado y guardado: \(restDuration) segundos")
        }
    }
    
    // Onboarding Manager
    @Published var onboardingManager = OnboardingManager()

    private var timer: Timer?
    private let userDefaults = UserDefaults.standard
    
    // LiveActivityManager opcional para evitar errores en versiones anteriores
    @MainActor
    private var liveActivityManager: LiveActivityManager? = {
        if #available(iOS 16.1, *) {
            return LiveActivityManager()
        }
        return nil
    }()

    init() {
        WorkoutDay.allCases.forEach { dailyWorkoutRecords[$0] = [] }
        loadData()
        print("WorkoutViewModel: Inicialización completada con restDuration: \(restDuration) segundos")
    }
    
    // Helper para obtener un Exercise base por su ID
    func getExercise(by id: UUID) -> Exercise? {
        return availableExercises.first(where: { $0.id == id })
    }
    
    private func recordHistory(for day: WorkoutDay) {
        let key = Calendar.current.startOfDay(for: Date())
        var historyForToday = workoutHistory[key] ?? [:]
        historyForToday[day] = self.dailyWorkoutRecords[day]
        workoutHistory[key] = historyForToday
        saveData()
    }

    func exercisesForDate(_ date: Date) -> [WorkoutDay: [WorkoutExercise]]? {
        let key = Calendar.current.startOfDay(for: date)
        return workoutHistory[key]
    }
    
    func hasWorkoutForDate(_ date: Date) -> Bool {
        let key = Calendar.current.startOfDay(for: date)
        guard let historyForDate = workoutHistory[key] else { return false }
        return !historyForDate.values.allSatisfy { $0.isEmpty }
    }
    
    private func saveData() {
        DispatchQueue.global(qos: .background).async {
            // Limpiar datos antiguos antes de guardar
            self.cleanupOldData()
            
            let encoder = JSONEncoder()
            do {
                // Guardar availableExercises
                if let enc = try? encoder.encode(self.availableExercises) {
                    let dataSize = enc.count
                    print("WorkoutViewModel: Guardando availableExercises - \(dataSize) bytes")
                    if dataSize < 1_000_000 { // Límite de 1MB por entrada
                        UserDefaults.standard.set(enc, forKey: "AvailableExercises")
                    } else {
                        print("WorkoutViewModel: ERROR - availableExercises excede el límite de tamaño")
                    }
                }
                
                // Guardar dailyWorkoutRecords
                if let encD = try? encoder.encode(self.dailyWorkoutRecords) {
                    let dataSize = encD.count
                    print("WorkoutViewModel: Guardando dailyWorkoutRecords - \(dataSize) bytes")
                    if dataSize < 1_000_000 {
                        UserDefaults.standard.set(encD, forKey: "DailyWorkoutRecords")
                    } else {
                        print("WorkoutViewModel: ERROR - dailyWorkoutRecords excede el límite de tamaño")
                    }
                }
                
                // Guardar workoutHistory (limitado)
                if let encH = try? encoder.encode(self.workoutHistory) {
                    let dataSize = encH.count
                    print("WorkoutViewModel: Guardando workoutHistory - \(dataSize) bytes")
                    if dataSize < 1_000_000 {
                        UserDefaults.standard.set(encH, forKey: "WorkoutHistory")
                    } else {
                        print("WorkoutViewModel: ERROR - workoutHistory excede el límite de tamaño")
                    }
                }
                
                // Guardar bodyWeightHistory (limitado)
                if let encW = try? encoder.encode(self.bodyWeightHistory) {
                    let dataSize = encW.count
                    print("WorkoutViewModel: Guardando bodyWeightHistory - \(dataSize) bytes")
                    if dataSize < 1_000_000 {
                        UserDefaults.standard.set(encW, forKey: "BodyWeightHistory")
                    } else {
                        print("WorkoutViewModel: ERROR - bodyWeightHistory excede el límite de tamaño")
                    }
                }
                
                // Guardar activeDays
                if let encA = try? encoder.encode(self.activeDays) {
                    let dataSize = encA.count
                    print("WorkoutViewModel: Guardando activeDays - \(dataSize) bytes")
                    if dataSize < 100_000 {
                        UserDefaults.standard.set(encA, forKey: "ActiveDays")
                    } else {
                        print("WorkoutViewModel: ERROR - activeDays excede el límite de tamaño")
                    }
                }
                
                UserDefaults.standard.set(self.restDuration, forKey: "RestDuration")
                print("WorkoutViewModel: Datos guardados exitosamente")
                
            } catch {
                print("WorkoutViewModel: Error al guardar datos: \(error)")
            }
        }
    }
    
    private func cleanupOldData() {
        let calendar = Calendar.current
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        
        // Limpiar workoutHistory - mantener solo los últimos 6 meses
        let oldHistoryKeys = workoutHistory.keys.filter { $0 < sixMonthsAgo }
        for key in oldHistoryKeys {
            workoutHistory.removeValue(forKey: key)
        }
        
        // Limpiar bodyWeightHistory - mantener solo los últimos 6 meses
        let oldWeightKeys = bodyWeightHistory.keys.filter { $0 < sixMonthsAgo }
        for key in oldWeightKeys {
            bodyWeightHistory.removeValue(forKey: key)
        }
        
        print("WorkoutViewModel: Limpieza completada - removidos \(oldHistoryKeys.count) registros de historial y \(oldWeightKeys.count) registros de peso")
    }
    
    func completeSet(for workoutExerciseId: UUID, in day: WorkoutDay) {
        guard let recordIndex = dailyWorkoutRecords[day]?.firstIndex(where: { $0.id == workoutExerciseId }),
              let baseExercise = getExercise(by: dailyWorkoutRecords[day]![recordIndex].exerciseId) else { return }
        
        var record = dailyWorkoutRecords[day]![recordIndex]
        if record.completedSets < baseExercise.totalSets {
            record.completedSets += 1
            record.lastSetCompletedAt = Date()
            dailyWorkoutRecords[day]![recordIndex] = record
            recordHistory(for: day)
            
            // Haptic feedback para completar serie
            HapticManager.shared.setCompleted()
            
            if record.completedSets < baseExercise.totalSets { 
                startTimer(duration: baseExercise.restDuration, isEnabled: isTimerEnabled)
            }
        }
    }
    
    func addExercise(name: String, reps: Int, weight: Double, sets: Int, info: String, imageData: Data?, restDuration: Int, toDays selectedDays: Set<WorkoutDay>, sfSymbolIcon: String? = nil, iconColor: String = "blue") {
        let newBaseExercise = Exercise(
            id: UUID(),
            name: name,
            repetitions: reps,
            weight: weight,
            totalSets: sets,
            info: info,
            imageData: imageData,
            restDuration: restDuration,
            sfSymbolIcon: sfSymbolIcon,
            iconColor: iconColor
        )
        availableExercises.append(newBaseExercise)
        
        // Asignar este ejercicio a los días seleccionados
        for day in selectedDays {
            let newWorkoutRecord = WorkoutExercise(
                id: UUID(),
                exerciseId: newBaseExercise.id,
                completedSets: 0,
                lastSetCompletedAt: nil
            )
            dailyWorkoutRecords[day]?.append(newWorkoutRecord)
        }
        
        // Haptic feedback para añadir ejercicio
        HapticManager.shared.exerciseAdded()
        
        // Iniciar onboarding si es el primer ejercicio
        if onboardingManager.isFirstExercise {
            onboardingManager.startOnboarding()
        }
        
        saveData()
    }
    
    func toggleDay(_ day: WorkoutDay) { 
        if let idx = activeDays.firstIndex(of: day) { 
            activeDays.remove(at: idx) 
        } else { 
            activeDays.append(day)
            activeDays.sort { WorkoutDay.allCases.firstIndex(of: $0)! < WorkoutDay.allCases.firstIndex(of: $1)! } 
        }
        
        // Haptic feedback para cambiar día
        HapticManager.shared.selectionFeedback()
        
        saveData() 
    }
    
    func removeExercise(recordId: UUID, from day: WorkoutDay) {
        dailyWorkoutRecords[day]?.removeAll { $0.id == recordId }
        recordHistory(for: day)
    }
    
    func undoLastSet(for workoutExerciseId: UUID, in day: WorkoutDay) {
        guard let recordIndex = dailyWorkoutRecords[day]?.firstIndex(where: { $0.id == workoutExerciseId }) else { return }
        
        var record = dailyWorkoutRecords[day]![recordIndex]
        if record.completedSets > 0 {
            record.completedSets -= 1
            if record.completedSets == 0 { record.lastSetCompletedAt = nil }
            dailyWorkoutRecords[day]![recordIndex] = record
            recordHistory(for: day)
            
            // Haptic feedback para deshacer set
            HapticManager.shared.warning()
        }
    }
    
    func updateBodyWeight(for date: Date, weight: Double) { 
        let key = Calendar.current.startOfDay(for: date)
        bodyWeightHistory[key] = weight
        
        // Haptic feedback para actualizar peso
        HapticManager.shared.success()
        
        saveData()
    }
    
    func bodyWeightForDate(_ date: Date) -> Double? { 
        let key = Calendar.current.startOfDay(for: date)
        return bodyWeightHistory[key] 
    }
    
    func progressForDay(_ day: WorkoutDay) -> Double {
        guard let records = dailyWorkoutRecords[day], !records.isEmpty else { return 0 }
        
        var totalSets = 0
        var completedSets = 0
        
        for record in records {
            if let baseExercise = getExercise(by: record.exerciseId) {
                totalSets += baseExercise.totalSets
                completedSets += record.completedSets
            }
        }
        return totalSets > 0 ? Double(completedSets) / Double(totalSets) : 0
    }
    func updateRestDuration(_ duration: Int) {
        restDuration = duration
        timeRemaining = duration
        print("WorkoutViewModel: restDuration actualizado a \(duration) segundos")
        saveData()
    }
    
    func updateExerciseRestDuration(_ exerciseId: UUID, newDuration: Int) {
        if let index = availableExercises.firstIndex(where: { $0.id == exerciseId }) {
            availableExercises[index].restDuration = newDuration
            saveData()
        }
    }
    
    func updateBaseExercise(_ updatedBaseExercise: Exercise) {
        if let index = availableExercises.firstIndex(where: { $0.id == updatedBaseExercise.id }) {
            availableExercises[index] = updatedBaseExercise
            saveData()
        }
    }
    
    func reassignExercise(exerciseId: UUID, toDays newDays: Set<WorkoutDay>) {
        guard let _ = getExercise(by: exerciseId) else { return }

        // 1. Eliminar todas las ocurrencias actuales de este ejercicio de todos los días
        for day in WorkoutDay.allCases {
            dailyWorkoutRecords[day]?.removeAll { $0.exerciseId == exerciseId }
        }

        // 2. Añadir nuevas ocurrencias solo a los newDays
        for day in newDays {
            let newWorkoutRecord = WorkoutExercise(
                id: UUID(),
                exerciseId: exerciseId,
                completedSets: 0,
                lastSetCompletedAt: nil
            )
            dailyWorkoutRecords[day]?.append(newWorkoutRecord)
        }
        saveData()
    }
    
    func removeExercise(baseExercise: Exercise) {
        // Eliminar de availableExercises
        availableExercises.removeAll { $0.id == baseExercise.id }
        
        // Eliminar todas las ocurrencias diarias de este ejercicio
        for day in WorkoutDay.allCases {
            dailyWorkoutRecords[day]?.removeAll { $0.exerciseId == baseExercise.id }
        }
        
        // Haptic feedback para eliminar ejercicio
        HapticManager.shared.exerciseDeleted()
        
        saveData()
    }
    
    func startRestTimer() { 
        timerActive = true
        timeRemaining = restDuration
        currentTimerDuration = restDuration
        print("WorkoutViewModel: Timer iniciado con duración: \(restDuration) segundos")
        
        // Iniciar Live Activity si está disponible
        Task { @MainActor in
            if #available(iOS 16.1, *) {
                liveActivityManager?.startTimerActivity(exerciseName: "Descanso", totalTime: restDuration)
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in 
            if self.timeRemaining > 0 { 
                self.timeRemaining -= 1
                
                // Actualizar Live Activity
                Task { @MainActor in
                    if #available(iOS 16.1, *) {
                        self.liveActivityManager?.updateTimerActivity(
                            timeRemaining: self.timeRemaining,
                            totalTime: self.restDuration,
                            isActive: true
                        )
                    }
                }
            } else { 
                self.stopTimer()
                AudioServicesPlaySystemSound(1057)
            }
        }
    }
    
    func stopTimer() { 
        timer?.invalidate()
        timer = nil
        timerActive = false
        timeRemaining = currentTimerDuration // Restaurar al valor original
        
        // Haptic feedback para detener timer
        HapticManager.shared.timerStopped()
        
        // Cancelar notificación programada
        NotificationManager.shared.cancelRestNotification()
        
        // Terminar Live Activity
        Task { @MainActor in
            if #available(iOS 16.1, *) {
                liveActivityManager?.endTimerActivity()
            }
        }
    }
    private func loadData() {
        let decoder = JSONDecoder()
        
        // Cargar availableExercises
        if let data = userDefaults.data(forKey: "AvailableExercises") {
            print("WorkoutViewModel: Cargando availableExercises - \(data.count) bytes")
            if let decoded = try? decoder.decode([Exercise].self, from: data) {
                availableExercises = decoded
            }
        }
        
        // Cargar dailyWorkoutRecords
        if let data = userDefaults.data(forKey: "DailyWorkoutRecords") {
            print("WorkoutViewModel: Cargando dailyWorkoutRecords - \(data.count) bytes")
            if let decoded = try? decoder.decode([WorkoutDay: [WorkoutExercise]].self, from: data) {
                dailyWorkoutRecords = decoded
            }
        }
        
        // Cargar workoutHistory
        if let data = userDefaults.data(forKey: "WorkoutHistory") {
            print("WorkoutViewModel: Cargando workoutHistory - \(data.count) bytes")
            if data.count > 3_000_000 { // Si es mayor a 3MB, hay un problema
                print("WorkoutViewModel: ADVERTENCIA - workoutHistory muy grande, ejecutando limpieza de emergencia")
                // En lugar de cargar datos corruptos, limpiar
                userDefaults.removeObject(forKey: "WorkoutHistory")
                workoutHistory = [:]
            } else if let decoded = try? decoder.decode([Date: [WorkoutDay: [WorkoutExercise]]].self, from: data) {
                workoutHistory = decoded
            }
        }
        
        // Cargar bodyWeightHistory
        if let data = userDefaults.data(forKey: "BodyWeightHistory") {
            print("WorkoutViewModel: Cargando bodyWeightHistory - \(data.count) bytes")
            if data.count > 1_000_000 { // Si es mayor a 1MB, limpiar
                print("WorkoutViewModel: ADVERTENCIA - bodyWeightHistory muy grande, ejecutando limpieza")
                userDefaults.removeObject(forKey: "BodyWeightHistory")
                bodyWeightHistory = [:]
            } else if let decoded = try? decoder.decode([Date: Double].self, from: data) {
                bodyWeightHistory = decoded
            }
        }
        
        // Cargar días activos
        if let data = userDefaults.data(forKey: "ActiveDays") {
            print("WorkoutViewModel: Cargando activeDays - \(data.count) bytes")
            if let decoded = try? decoder.decode([WorkoutDay].self, from: data) {
                activeDays = decoded
            }
        }
        
        // Cargar duración del descanso
        if let savedRestDuration = userDefaults.object(forKey: "RestDuration") as? Int {
            restDuration = savedRestDuration
            print("WorkoutViewModel: restDuration cargado de UserDefaults: \(restDuration) segundos")
        } else {
            print("WorkoutViewModel: No se encontró restDuration guardado. Usando valor por defecto: \(restDuration) segundos")
        }
        
        // Mostrar información del tamaño de datos
        print("WorkoutViewModel: Datos cargados exitosamente")
        print(getDataSizeInfo())
        
        // Asegurarse de que todos los días tengan un array vacío si no hay records
        WorkoutDay.allCases.forEach { day in
            if dailyWorkoutRecords[day] == nil {
                dailyWorkoutRecords[day] = []
            }
        }
    }
    func resetAllData() {
        self.availableExercises = []
        self.dailyWorkoutRecords = [:]
        WorkoutDay.allCases.forEach { dailyWorkoutRecords[$0] = [] }
        self.workoutHistory = [:]
        self.bodyWeightHistory = [:]
        self.activeDays = WorkoutDay.allCases
        userDefaults.removeObject(forKey: "AvailableExercises")
        userDefaults.removeObject(forKey: "DailyWorkoutRecords")
        userDefaults.removeObject(forKey: "WorkoutHistory")
        userDefaults.removeObject(forKey: "BodyWeightHistory")
        userDefaults.removeObject(forKey: "ActiveDays")
        userDefaults.removeObject(forKey: "RestDuration")
    }
    
    // MARK: - Weekly Statistics
    
    func weeklyProgress() -> Double {
        var totalSets = 0
        var completedSets = 0
        
        for day in activeDays {
            if let records = dailyWorkoutRecords[day] {
                for record in records {
                    if let baseExercise = getExercise(by: record.exerciseId) {
                        totalSets += baseExercise.totalSets
                        completedSets += record.completedSets
                    }
                }
            }
        }
        return totalSets > 0 ? Double(completedSets) / Double(totalSets) : 0
    }
    
    func weeklyCompletedSets() -> Int {
        var total = 0
        for day in activeDays {
            if let records = dailyWorkoutRecords[day] {
                for record in records {
                    total += record.completedSets
                }
            }
        }
        return total
    }
    
    func weeklyTotalSets() -> Int {
        var total = 0
        for day in activeDays {
            if let records = dailyWorkoutRecords[day] {
                for record in records {
                    if let baseExercise = getExercise(by: record.exerciseId) {
                        total += baseExercise.totalSets
                    }
                }
            }
        }
        return total
    }
    
    func weeklyExercisesSummary() -> [(day: WorkoutDay, exercises: [(baseExercise: Exercise, record: WorkoutExercise)])] {
        return WorkoutDay.allCases.compactMap { day -> (day: WorkoutDay, exercises: [(baseExercise: Exercise, record: WorkoutExercise)])? in
            guard let records = dailyWorkoutRecords[day], !records.isEmpty else { return nil }
            
            let exercisesWithRecords = records.compactMap { record -> (baseExercise: Exercise, record: WorkoutExercise)? in
                guard let baseExercise = getExercise(by: record.exerciseId) else { return nil }
                return (baseExercise: baseExercise, record: record)
            }
            guard !exercisesWithRecords.isEmpty else { return nil }
            return (day: day, exercises: exercisesWithRecords)
        }.sorted { (d1, d2) in
            WorkoutDay.allCases.firstIndex(of: d1.day)! < WorkoutDay.allCases.firstIndex(of: d2.day)!
        }
    }
    
    func consecutiveWorkoutDays() -> Int {
        let sortedHistoryDates = workoutHistory.keys.sorted(by: >)
        var consecutiveDays = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        
        for historyDate in sortedHistoryDates {
            if historyDate <= currentDate && historyDate >= Calendar.current.date(byAdding: .day, value: -consecutiveDays - 1, to: currentDate)! {
                if let dayHistory = workoutHistory[historyDate] {
                    let hasCompletedWorkout = dayHistory.values.contains { records in
                        records.contains { record in
                            record.completedSets > 0
                        }
                    }
                    if hasCompletedWorkout {
                        consecutiveDays += 1
                        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                    } else {
                        break
                    }
                } else {
                    break
                }
            } else if historyDate > currentDate {
                continue
            } else {
                break
            }
        }
        
        return consecutiveDays
    }
    
    func bestWorkoutDay() -> WorkoutDay? {
        var dayProgress: [WorkoutDay: Double] = [:]
        
        for day in WorkoutDay.allCases {
            dayProgress[day] = progressForDay(day)
        }
        
        return dayProgress.max(by: { $0.value < $1.value })?.key
    }
    
    func totalUniqueExercises() -> Int {
        return availableExercises.count
    }
    
    func estimatedWeeklyWorkoutTime() -> Int {
        // Estimate: 1 minute per set + 2 minutes rest between sets
        let totalSets = weeklyTotalSets()
        return totalSets > 0 ? totalSets * 3 : 0 // 3 minutes per set (1 for exercise + 2 for rest)
    }
    
    // MARK: - Exercise Management Methods
    
    func addExercise(_ exercise: Exercise, to day: WorkoutDay) {
        // Esta función se mantiene para compatibilidad, pero ahora usa la nueva estructura
        if !availableExercises.contains(where: { $0.id == exercise.id }) {
            availableExercises.append(exercise)
        }
        
        let newWorkoutRecord = WorkoutExercise(
            id: UUID(),
            exerciseId: exercise.id,
            completedSets: 0,
            lastSetCompletedAt: nil
        )
        dailyWorkoutRecords[day]?.append(newWorkoutRecord)
        saveData()
    }
    
    func removeExercise(_ exercise: Exercise, from day: WorkoutDay) {
        // Solo remover el record de ese día específico
        dailyWorkoutRecords[day]?.removeAll { $0.exerciseId == exercise.id }
        saveData()
    }
    
    func removeExercise(withId id: UUID, from day: WorkoutDay) {
        // Remover por ID de WorkoutExercise (no Exercise base)
        dailyWorkoutRecords[day]?.removeAll { $0.id == id }
        saveData()
    }
    
    func updateExercise(_ updatedExercise: Exercise, in day: WorkoutDay) {
        // Actualizar la definición base
        if let index = availableExercises.firstIndex(where: { $0.id == updatedExercise.id }) {
            availableExercises[index] = updatedExercise
            saveData()
        }
    }
    
    // MARK: - Set Completion Methods
    
    func toggleSetCompletion(exercise: Exercise, setIndex: Int) {
        // Esta función necesita ser actualizada para usar WorkoutExercise
        // Por ahora, vamos a buscar el primer record de este ejercicio
        for day in WorkoutDay.allCases {
            if let recordIndex = dailyWorkoutRecords[day]?.firstIndex(where: { $0.exerciseId == exercise.id }) {
                var record = dailyWorkoutRecords[day]![recordIndex]
                
                if setIndex == record.completedSets {
                    // Completar la siguiente serie
                    record.completedSets += 1
                    record.lastSetCompletedAt = Date()
                    
                    // Iniciar timer automáticamente si no es el último set
                    if record.completedSets < exercise.totalSets {
                        startTimer(duration: exercise.restDuration, isEnabled: isTimerEnabled)
                    }
                } else if setIndex == record.completedSets - 1 {
                    // Desmarcar la última serie completada
                    record.completedSets -= 1
                    if record.completedSets == 0 {
                        record.lastSetCompletedAt = nil
                    }
                }
                
                dailyWorkoutRecords[day]![recordIndex] = record
                recordHistory(for: day)
                break
            }
        }
    }
    
    private func findDayForExercise(_ exercise: Exercise) -> WorkoutDay? {
        for day in WorkoutDay.allCases {
            if dailyWorkoutRecords[day]?.contains(where: { $0.exerciseId == exercise.id }) == true {
                return day
            }
        }
        return nil
    }
    
    // MARK: - Timer Methods
    
    func startTimer(duration: Int, isEnabled: Bool = true) {
        guard isEnabled else {
            print("WorkoutViewModel: Timer desactivado por configuración")
            return
        }
        
        stopTimer() // Detener cualquier timer existente
        timeRemaining = duration
        currentTimerDuration = duration // Guardar la duración actual del timer
        timerActive = true
        
        // Haptic feedback para iniciar timer
        HapticManager.shared.timerStarted()
        
        // Programar notificación para cuando termine el timer
        NotificationManager.shared.scheduleRestNotification(after: TimeInterval(duration))
        
        print("WorkoutViewModel: Timer iniciado con duración: \(duration) segundos")
        
        // Iniciar Live Activity si está disponible
        Task { @MainActor in
            if #available(iOS 16.1, *) {
                liveActivityManager?.startTimerActivity(exerciseName: "Descanso", totalTime: duration)
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    
                    // Actualizar Live Activity
                    Task { @MainActor in
                        if #available(iOS 16.1, *) {
                            self.liveActivityManager?.updateTimerActivity(
                                timeRemaining: self.timeRemaining,
                                totalTime: duration,
                                isActive: true
                            )
                        }
                    }
                } else {
                    self.completeTimer()
                }
            }
        }
    }
    
    private func completeTimer() {
        stopTimer()
        
        // Haptic feedback mejorado para completar timer
        HapticManager.shared.timerCompleted()
        
        // Notificación local si la app está en background
        scheduleTimerCompletionNotification()
    }
    
    private func scheduleTimerCompletionNotification() {
        // Esta función podría implementar notificaciones locales
        // Por ahora solo hacemos vibración
    }
    
    // Función para actualizar el estado del timer desde las vistas
    func updateTimerEnabledState(_ isEnabled: Bool) {
        isTimerEnabled = isEnabled
    }
    
    // MARK: - Métodos de limpieza de datos
    func clearAllData() {
        // Limpiar todas las estructuras de datos
        availableExercises.removeAll()
        dailyWorkoutRecords.removeAll()
        workoutHistory.removeAll()
        bodyWeightHistory.removeAll()
        activeDays = WorkoutDay.allCases
        
        // Limpiar UserDefaults
        UserDefaults.standard.removeObject(forKey: "AvailableExercises")
        UserDefaults.standard.removeObject(forKey: "DailyWorkoutRecords")
        UserDefaults.standard.removeObject(forKey: "WorkoutHistory")
        UserDefaults.standard.removeObject(forKey: "BodyWeightHistory")
        UserDefaults.standard.removeObject(forKey: "ActiveDays")
        
        print("WorkoutViewModel: Todos los datos han sido limpiados")
    }
    
    func getDataSizeInfo() -> String {
        let encoder = JSONEncoder()
        var info = "Tamaño de datos guardados:\n"
        
        if let enc = try? encoder.encode(availableExercises) {
            info += "- Ejercicios disponibles: \(enc.count) bytes\n"
        }
        
        if let enc = try? encoder.encode(dailyWorkoutRecords) {
            info += "- Registros diarios: \(enc.count) bytes\n"
        }
        
        if let enc = try? encoder.encode(workoutHistory) {
            info += "- Historial de entrenamientos: \(enc.count) bytes\n"
        }
        
        if let enc = try? encoder.encode(bodyWeightHistory) {
            info += "- Historial de peso: \(enc.count) bytes\n"
        }
        
        if let enc = try? encoder.encode(activeDays) {
            info += "- Días activos: \(enc.count) bytes\n"
        }
        
        return info
    }
    
    // Método para emergencias - limpiar solo si los datos son demasiado grandes
    func emergencyCleanup() {
        let encoder = JSONEncoder()
        
        // Verificar cada estructura de datos
        if let enc = try? encoder.encode(workoutHistory), enc.count > 2_000_000 {
            // Si el historial es mayor a 2MB, mantener solo el último mes
            let calendar = Calendar.current
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            
            let oldKeys = workoutHistory.keys.filter { $0 < oneMonthAgo }
            for key in oldKeys {
                workoutHistory.removeValue(forKey: key)
            }
            print("WorkoutViewModel: Limpieza de emergencia del historial completada")
        }
        
        if let enc = try? encoder.encode(bodyWeightHistory), enc.count > 500_000 {
            // Si el historial de peso es mayor a 500KB, mantener solo el último mes
            let calendar = Calendar.current
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            
            let oldKeys = bodyWeightHistory.keys.filter { $0 < oneMonthAgo }
            for key in oldKeys {
                bodyWeightHistory.removeValue(forKey: key)
            }
            print("WorkoutViewModel: Limpieza de emergencia del peso completada")
        }
        
        // Guardar datos después de la limpieza
        saveData()
    }
}
