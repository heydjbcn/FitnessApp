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
    
    // Nuevo método que solo muestra ejercicios COMPLETADOS en el día seleccionado
    func completedExercisesForDate(_ date: Date) -> [WorkoutDay: [WorkoutExercise]]? {
        let key = Calendar.current.startOfDay(for: date)
        guard let historyForDate = workoutHistory[key] else { return nil }
        
        var filteredHistory: [WorkoutDay: [WorkoutExercise]] = [:]
        
        for (workoutDay, exercises) in historyForDate {
            // Filtrar solo ejercicios que fueron realmente completados ese día
            let completedExercises = exercises.filter { workoutExercise in
                // Un ejercicio se considera "completado en este día" si:
                // 1. Tiene sets completados Y
                // 2. La fecha de última completación es del día seleccionado
                guard workoutExercise.completedSets > 0,
                      let lastCompleted = workoutExercise.lastSetCompletedAt else {
                    return false
                }
                
                let completionDate = Calendar.current.startOfDay(for: lastCompleted)
                let selectedDate = Calendar.current.startOfDay(for: date)
                
                return completionDate == selectedDate
            }
            
            // Solo incluir días que tengan ejercicios completados
            if !completedExercises.isEmpty {
                filteredHistory[workoutDay] = completedExercises
            }
        }
        
        return filteredHistory.isEmpty ? nil : filteredHistory
    }
    
    func hasWorkoutForDate(_ date: Date) -> Bool {
        // Verificar si hay ejercicios completados para esta fecha
        guard let completedExercises = completedExercisesForDate(date) else { return false }
        return !completedExercises.values.allSatisfy { $0.isEmpty }
    }
    
    private func saveData() {
        DispatchQueue.global(qos: .background).async {
            // Limpiar datos antiguos antes de guardar
            self.cleanupOldData()
            
            let encoder = JSONEncoder()
            
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
    
    func addExercise(name: String, reps: Int, weight: Double, sets: Int, info: String, imageData: Data?, restDuration: Int, toDays selectedDays: Set<WorkoutDay>, sfSymbolIcon: String? = nil, iconColor: String = "blue", segundos: Int = 0, rir: Int = 0) {
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
            iconColor: iconColor,
            segundos: segundos,
            rir: rir
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
        
        // Verificar si es la primera vez que se abre la app
        let isFirstLaunch = !userDefaults.bool(forKey: "HasLaunchedBefore")
        
        // Cargar availableExercises
        if let data = userDefaults.data(forKey: "AvailableExercises") {
            print("WorkoutViewModel: Cargando availableExercises - \(data.count) bytes")
            if let decoded = try? decoder.decode([Exercise].self, from: data) {
                availableExercises = decoded
            }
        } else if isFirstLaunch {
            // Primera vez - configurar datos por defecto
            setupDefaultData()
            userDefaults.set(true, forKey: "HasLaunchedBefore")
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
    
    private func setupDefaultData() {
        print("WorkoutViewModel: Configurando datos por defecto...")
        
        // Crear ejercicios por defecto basados en la rutina
        let defaultExercises = createDefaultExercises()
        availableExercises = defaultExercises
        
        // Configurar días activos (Lunes, Miércoles, Viernes)
        activeDays = [.monday, .wednesday, .friday]
        
        // Configurar rutina diaria
        setupDefaultWorkoutPlan(exercises: defaultExercises)
        
        // Crear historial de entrenamiento del último mes
        createMonthlyWorkoutHistory()
        
        // Guardar datos
        saveData()
        
        print("WorkoutViewModel: Datos por defecto configurados exitosamente")
    }
    
    private func createDefaultExercises() -> [Exercise] {
        var exercises: [Exercise] = []
        
        // DÍA 1 - LUNES (Glúteos e Isquiosurales)
        exercises.append(Exercise(
            id: UUID(),
            name: "HIP THRUST MÁQUINA",
            repetitions: 10,
            weight: 65.0,
            totalSets: 4,
            info: "Enfoque en la contracción máxima del glúteo",
            imageData: nil,
            restDuration: 90,
            sfSymbolIcon: "figure.strengthtraining.traditional",
            iconColor: "pink"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "MÁQUINA DE ABDUCCIÓN",
            repetitions: 20,
            weight: 15.0,
            totalSets: 4,
            info: "Mantener tensión constante",
            imageData: nil,
            restDuration: 60,
            sfSymbolIcon: "figure.seated.side.air.upper.body.strengthtraining",
            iconColor: "pink"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "PESO MUERTO CON PESA RUSA",
            repetitions: 10,
            weight: 16.0,
            totalSets: 4,
            info: "Descenso controlado, activación de isquiosurales",
            imageData: nil,
            restDuration: 90,
            sfSymbolIcon: "figure.strengthtraining.functional",
            iconColor: "orange"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "FLEXIÓN DE RODILLA MÁQUINA TUMBADO",
            repetitions: 12,
            weight: 0,
            totalSets: 4,
            info: "Control en la fase excéntrica",
            imageData: nil,
            restDuration: 60,
            sfSymbolIcon: "figure.strengthtraining.traditional",
            iconColor: "red"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "FLEXIÓN DE RODILLA MÁQUINA SENTADO",
            repetitions: 12,
            weight: 0,
            totalSets: 4,
            info: "Máximo recorrido articular",
            imageData: nil,
            restDuration: 60,
            sfSymbolIcon: "figure.seated.side.air.upper.body.strengthtraining",
            iconColor: "red"
        ))
        
        // DÍA 2 - MIÉRCOLES (Espalda y Deltoides)
        exercises.append(Exercise(
            id: UUID(),
            name: "JALÓN AL PECHO TOMA NEUTRA ANCHO HOMBROS",
            repetitions: 12,
            weight: 0,
            totalSets: 4,
            info: "Activación completa del dorsal ancho",
            imageData: nil,
            restDuration: 90,
            sfSymbolIcon: "figure.strengthtraining.traditional",
            iconColor: "blue"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "REMO EN POLEA BAJA AGARRE SUPINO",
            repetitions: 10,
            weight: 0,
            totalSets: 4,
            info: "Retracción escapular máxima",
            imageData: nil,
            restDuration: 90,
            sfSymbolIcon: "figure.rowing",
            iconColor: "blue"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "REMO UNILATERAL CON APOYO EN PECHO",
            repetitions: 8,
            weight: 0,
            totalSets: 4,
            info: "Trabajo unilateral para equilibrio muscular",
            imageData: nil,
            restDuration: 60,
            sfSymbolIcon: "figure.strengthtraining.traditional",
            iconColor: "cyan"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "VUELO POSTERIOR DE HOMBROS EN MÁQUINA",
            repetitions: 10,
            weight: 0,
            totalSets: 4,
            info: "Deltoides posterior y romboides",
            imageData: nil,
            restDuration: 60,
            sfSymbolIcon: "figure.strengthtraining.traditional",
            iconColor: "purple"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "ELEVACIÓN LATERAL SENTADO MANCUERNAS",
            repetitions: 12,
            weight: 0,
            totalSets: 4,
            info: "Deltoides medio, control del movimiento",
            imageData: nil,
            restDuration: 60,
            sfSymbolIcon: "figure.seated.side.air.upper.body.strengthtraining",
            iconColor: "purple"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "ELEVACIÓN FRONTAL MANCUERNAS DE PIE",
            repetitions: 12,
            weight: 0,
            totalSets: 4,
            info: "Deltoides anterior, evitar impulso",
            imageData: nil,
            restDuration: 60,
            sfSymbolIcon: "figure.strengthtraining.traditional",
            iconColor: "yellow"
        ))
        
        // DÍA 3 - VIERNES (Cuádriceps)
        exercises.append(Exercise(
            id: UUID(),
            name: "HIP THRUST EN MÁQUINA",
            repetitions: 8,
            weight: 0,
            totalSets: 4,
            info: "Variante para activación previa",
            imageData: nil,
            restDuration: 90,
            sfSymbolIcon: "figure.strengthtraining.traditional",
            iconColor: "pink"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "SENTADILLA HACK",
            repetitions: 8,
            weight: 0,
            totalSets: 4,
            info: "Máxima profundidad, control de la carga",
            imageData: nil,
            restDuration: 120,
            sfSymbolIcon: "figure.squat",
            iconColor: "green"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "ZANCADA PIES EN SUELO",
            repetitions: 10,
            weight: 0,
            totalSets: 4,
            info: "Trabajo unilateral, estabilidad del core",
            imageData: nil,
            restDuration: 90,
            sfSymbolIcon: "figure.strengthtraining.functional",
            iconColor: "green"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "PRENSA DE PIERNA UNILATERAL",
            repetitions: 10,
            weight: 0,
            totalSets: 4,
            info: "Enfoque en cuádriceps, cada pierna por separado",
            imageData: nil,
            restDuration: 90,
            sfSymbolIcon: "figure.strengthtraining.traditional",
            iconColor: "green"
        ))
        
        exercises.append(Exercise(
            id: UUID(),
            name: "EXTENSIÓN RODILLA EN SILLA LEG EXTENSION",
            repetitions: 12,
            weight: 0,
            totalSets: 4,
            info: "Aislamiento del cuádriceps, contracción máxima",
            imageData: nil,
            restDuration: 60,
            sfSymbolIcon: "figure.seated.side.air.upper.body.strengthtraining",
            iconColor: "green"
        ))
        
        return exercises
    }
    
    private func setupDefaultWorkoutPlan(exercises: [Exercise]) {
        // Limpiar rutinas existentes
        dailyWorkoutRecords = [:]
        WorkoutDay.allCases.forEach { dailyWorkoutRecords[$0] = [] }
        
        // DÍA 1 - LUNES (Glúteos e Isquiosurales)
        let mondayExercises = exercises.filter { exercise in
            ["HIP THRUST MÁQUINA", "MÁQUINA DE ABDUCCIÓN", "PESO MUERTO CON PESA RUSA", 
             "FLEXIÓN DE RODILLA MÁQUINA TUMBADO", "FLEXIÓN DE RODILLA MÁQUINA SENTADO"].contains(exercise.name)
        }
        
        dailyWorkoutRecords[.monday] = mondayExercises.map { exercise in
            WorkoutExercise(id: UUID(), exerciseId: exercise.id, completedSets: 0)
        }
        
        // DÍA 2 - MIÉRCOLES (Espalda y Deltoides)
        let wednesdayExercises = exercises.filter { exercise in
            ["JALÓN AL PECHO TOMA NEUTRA ANCHO HOMBROS", "REMO EN POLEA BAJA AGARRE SUPINO", 
             "REMO UNILATERAL CON APOYO EN PECHO", "VUELO POSTERIOR DE HOMBROS EN MÁQUINA",
             "ELEVACIÓN LATERAL SENTADO MANCUERNAS", "ELEVACIÓN FRONTAL MANCUERNAS DE PIE"].contains(exercise.name)
        }
        
        dailyWorkoutRecords[.wednesday] = wednesdayExercises.map { exercise in
            WorkoutExercise(id: UUID(), exerciseId: exercise.id, completedSets: 0)
        }
        
        // DÍA 3 - VIERNES (Cuádriceps)
        let fridayExercises = exercises.filter { exercise in
            ["HIP THRUST EN MÁQUINA", "SENTADILLA HACK", "ZANCADA PIES EN SUELO", 
             "PRENSA DE PIERNA UNILATERAL", "EXTENSIÓN RODILLA EN SILLA LEG EXTENSION"].contains(exercise.name)
        }
        
        dailyWorkoutRecords[.friday] = fridayExercises.map { exercise in
            WorkoutExercise(id: UUID(), exerciseId: exercise.id, completedSets: 0)
        }
    }
    
    private func createMonthlyWorkoutHistory() {
        let calendar = Calendar.current
        let today = Date()
        
        // Crear historial para las últimas 4 semanas
        // Asumiendo que el último miércoles del mes fue el último entrenamiento
        
        var dates: [Date] = []
        
        // Generar fechas para los últimos entrenamientos (Lunes, Miércoles, Viernes)
        for weekOffset in (1...4).reversed() {
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) {
                // Encontrar lunes, miércoles y viernes de esa semana
                let weekdayOfWeekStart = calendar.component(.weekday, from: weekStart)
                let daysToMonday = (weekdayOfWeekStart == 1) ? 1 : 8 - weekdayOfWeekStart + 1
                
                if let monday = calendar.date(byAdding: .day, value: daysToMonday, to: weekStart),
                   let wednesday = calendar.date(byAdding: .day, value: 2, to: monday),
                   let friday = calendar.date(byAdding: .day, value: 4, to: monday) {
                    dates.append(contentsOf: [monday, wednesday, friday])
                }
            }
        }
        
        // Crear registros completados para cada fecha
        for date in dates {
            let dateKey = calendar.startOfDay(for: date)
            let dayOfWeek = calendar.component(.weekday, from: date)
            
            var historyForDate: [WorkoutDay: [WorkoutExercise]] = [:]
            
            switch dayOfWeek {
            case 2: // Lunes
                if let mondayWorkouts = dailyWorkoutRecords[.monday] {
                    let completedWorkouts = mondayWorkouts.map { workout in
                        var completed = workout
                        if let exercise = getExercise(by: workout.exerciseId) {
                            completed.completedSets = exercise.totalSets // Completar todas las series
                            completed.lastSetCompletedAt = date
                        }
                        return completed
                    }
                    historyForDate[.monday] = completedWorkouts
                }
                
            case 4: // Miércoles
                if let wednesdayWorkouts = dailyWorkoutRecords[.wednesday] {
                    let completedWorkouts = wednesdayWorkouts.map { workout in
                        var completed = workout
                        if let exercise = getExercise(by: workout.exerciseId) {
                            completed.completedSets = exercise.totalSets // Completar todas las series
                            completed.lastSetCompletedAt = date
                        }
                        return completed
                    }
                    historyForDate[.wednesday] = completedWorkouts
                }
                
            case 6: // Viernes
                if let fridayWorkouts = dailyWorkoutRecords[.friday] {
                    let completedWorkouts = fridayWorkouts.map { workout in
                        var completed = workout
                        if let exercise = getExercise(by: workout.exerciseId) {
                            completed.completedSets = exercise.totalSets // Completar todas las series
                            completed.lastSetCompletedAt = date
                        }
                        return completed
                    }
                    historyForDate[.friday] = completedWorkouts
                }
                
            default:
                break
            }
            
            if !historyForDate.isEmpty {
                workoutHistory[dateKey] = historyForDate
            }
        }
        
        // Simular algunos registros de peso corporal
        for weekOffset in (1...4).reversed() {
            if let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) {
                let weight = 70.0 + Double.random(in: -1.5...1.5) // Peso base con variaciones
                bodyWeightHistory[calendar.startOfDay(for: date)] = weight
            }
        }
        
        print("WorkoutViewModel: Historial de entrenamiento creado para \(dates.count) días")
    }
    
    func resetAllData() {
        print("🚨 WORKOUT_VIEW_MODEL: ¡Se ha llamado a resetAllData! Borrando TODOS los datos.")
        print("📍 STACK TRACE: \(Thread.callStackSymbols.prefix(5).joined(separator: "\n"))")
        
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
        userDefaults.removeObject(forKey: "HasLaunchedBefore")
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
    
    func getTotalWorkoutDuration() -> Int {
        // Calcular duración aproximada basada en entrenamientos completados
        var totalSets = 0
        
        for day in WorkoutDay.allCases {
            let exercises = dailyWorkoutRecords[day] ?? []
            for exercise in exercises {
                totalSets += exercise.completedSets
            }
        }
        
        // Estimación: 1 minuto por serie + tiempo de descanso
        let estimatedMinutes = totalSets * 1 + (totalSets > 0 ? (totalSets - 1) * (restDuration / 60) : 0)
        return estimatedMinutes * 60 // Convertir a segundos
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
        print("🚨 WORKOUT_VIEW_MODEL: ¡Se ha llamado a clearAllData! Borrando datos de entrenamiento.")
        print("📍 STACK TRACE: \(Thread.callStackSymbols.prefix(5).joined(separator: "\n"))")
        
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
        print("🔧 WORKOUT_VIEW_MODEL: ¡Se ha llamado a emergencyCleanup! Limpiando datos por tamaño.")
        print("📍 STACK TRACE: \(Thread.callStackSymbols.prefix(5).joined(separator: "\n"))")
        
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
    
    // FUNCIÓN DE PRUEBA TEMPORAL - Para verificar que los segundos funcionan
    func addTestExerciseWithSeconds() {
        let testExercise = Exercise(
            id: UUID(),
            name: "PRUEBA SEGUNDOS",
            repetitions: 0, // Sin repeticiones
            weight: 0,
            totalSets: 3,
            info: "Ejercicio de prueba con segundos",
            imageData: nil,
            restDuration: 60,
            sfSymbolIcon: "timer",
            iconColor: "red",
            segundos: 45, // 45 segundos
            rir: 0
        )
        
        availableExercises.append(testExercise)
        
        // Agregar a todos los días
        for day in WorkoutDay.allCases {
            let workoutRecord = WorkoutExercise(
                id: UUID(),
                exerciseId: testExercise.id,
                completedSets: 0,
                lastSetCompletedAt: nil
            )
            dailyWorkoutRecords[day]?.append(workoutRecord)
        }
        
        saveData()
        print("🔥 TEST: Ejercicio de prueba con 45 segundos agregado a todos los días")
    }
}
