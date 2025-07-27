//
//  WorkoutViewModel.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//  Updated with Memory & Performance Optimizations
//

import SwiftUI
import Combine
import Foundation
import AudioToolbox
import UIKit

class WorkoutViewModel: ObservableObject {
    @Published var activeDays: [WorkoutDay] = WorkoutDay.allCases
    
    // Almacena las DEFINICIONES ÚNICAS de los ejercicios
    @Published var availableExercises: [Exercise] = []
    
    // Almacena el progreso diario. Cada WorkoutExercise se refiere a un Exercise por su ID
    @Published var dailyWorkoutRecords: [WorkoutDay: [WorkoutExercise]] = [:]
    
    @Published var workoutHistory: [Date: [WorkoutDay: [WorkoutExercise]]] = [:]
    @Published var bodyWeightHistory: [Date: Double] = [:]
    
    // NUEVO: Notas de sesión por fecha
    @Published var sessionNotes: [Date: String] = [:]
    
    @Published var timerActive = false
    @Published var timeRemaining = 120
    @Published var currentTimerDuration: Int = 120 // Duración del timer actual
    @Published var isTimerEnabled = true // Estado del timer desde ThemeManager
    @Published var restDuration: Int = 120 // Tiempo de descanso personalizable (por defecto 2 minutos)
    
    // Variable privada para controlar las actualizaciones
    private var isUpdatingRestDuration = false
    private var isSaving = false // Controla las operaciones de guardado concurrentes
    
    // Onboarding Manager
    @Published var onboardingManager = OnboardingManager()

    // NUEVO: Control de timer mejorado
    private var timer: Timer?
    private var timerWorkItem: DispatchWorkItem?
    
    // NUEVO: Límites de datos
    private let MAX_HISTORY_DAYS = 90 // Solo 3 meses de historial
    private let MAX_USERDEFAULTS_SIZE = 500_000 // 500KB máximo por clave
    
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
        
        // Escuchar advertencias de memoria del sistema
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        loadData()
        print("WorkoutViewModel: Inicialización completada con restDuration: \(restDuration) segundos")
    }
    
    // NUEVO: Manejo de advertencias de memoria
    @objc private func handleMemoryWarning() {
        print("🧹 WorkoutViewModel: Limpieza por advertencia de memoria")
        
        // Limpiar datos no esenciales
        cleanupNonEssentialData()
        
        // Detener timer si está activo
        if timerActive {
            stopTimer()
        }
        
        // Forzar guardado y limpieza
        saveData()
    }
    
    // NUEVO: Limpieza de datos no esenciales
    private func cleanupNonEssentialData() {
        let calendar = Calendar.current
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        
        let oldKeys = workoutHistory.keys.filter { $0 < twoWeeksAgo }
        for key in oldKeys {
            workoutHistory.removeValue(forKey: key)
        }
        
        let oldNoteKeys = sessionNotes.keys.filter { $0 < twoWeeksAgo }
        for key in oldNoteKeys {
            sessionNotes.removeValue(forKey: key)
        }
        
        print("🧹 Limpiados \(oldKeys.count) registros antiguos y \(oldNoteKeys.count) notas")
    }
    
    // NUEVO: Limpieza en deinit
    deinit {
        print("🧹 WorkoutViewModel: Iniciando deinit...")
        
        // Detener todos los observers de forma segura
        DispatchQueue.main.async {
            NotificationCenter.default.removeObserver(self)
        }
        
        // Limpiar timers de forma segura
        DispatchQueue.main.sync {
            self.timer?.invalidate()
            self.timer = nil
            self.timerWorkItem?.cancel()
            self.timerWorkItem = nil
            UIApplication.shared.isIdleTimerDisabled = false
        }
        
        // Resetear flags
        isUpdatingRestDuration = false
        
        print("WorkoutViewModel: deinit completo - recursos limpiados")
    }
    
    // MARK: - Safe Update Functions
    
    /// Actualiza restDuration de forma segura para evitar bucles infinitos
    func updateRestDuration(_ newDuration: Int) {
        guard !isUpdatingRestDuration else { return }
        isUpdatingRestDuration = true
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.restDuration = newDuration
            UserDefaults.standard.set(newDuration, forKey: "RestDuration")
            print("WorkoutViewModel: restDuration actualizado y guardado: \(newDuration) segundos")
            self.isUpdatingRestDuration = false
        }
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
            let hasScheduledExercises = !availableExercises.isEmpty
            
            if hasScheduledExercises {
                let completedExercises = exercises.filter { workoutExercise in
                    guard workoutExercise.completedSets > 0,
                          let lastCompleted = workoutExercise.lastSetCompletedAt else {
                        return false
                    }
                        
                    let completionDate = Calendar.current.startOfDay(for: lastCompleted)
                    let selectedDate = Calendar.current.startOfDay(for: date)
                        
                    return completionDate == selectedDate
                }
                    
                if !completedExercises.isEmpty {
                    filteredHistory[workoutDay] = completedExercises
                }
            }
        }
            
        return filteredHistory.isEmpty ? nil : filteredHistory
    }
    
    func hasWorkoutForDate(_ date: Date) -> Bool {
        guard let completedExercises = completedExercisesForDate(date) else { return false }
        return !completedExercises.values.allSatisfy { $0.isEmpty }
    }
    
    // MARK: - Session Notes Management
    func getSessionNote(for date: Date) -> String? {
        let key = Calendar.current.startOfDay(for: date)
            
        if sessionNotes[key] == nil && Calendar.current.isDateInToday(date) {
            let exampleNote = "Entrenamiento completado con buena energía. Se sintió más fácil el peso de hoy, quizás puedo subir en la próxima sesión. 💪"
            sessionNotes[key] = exampleNote
            saveData()
            return exampleNote
        }
            
        return sessionNotes[key]
    }
    
    func saveSessionNote(_ note: String, for date: Date) {
        let key = Calendar.current.startOfDay(for: date)
        if note.isEmpty {
            sessionNotes.removeValue(forKey: key)
        } else {
            sessionNotes[key] = note
        }
        saveData()
    }
    
    // MARK: - Funciones para borrar historial de un día específico
    
    func deleteCompletedExercisesForDate(_ date: Date) {
        let key = Calendar.current.startOfDay(for: date)
        workoutHistory.removeValue(forKey: key)
        saveData()
    }
    
    func deleteBodyWeightForDate(_ date: Date) {
        let key = Calendar.current.startOfDay(for: date)
        bodyWeightHistory.removeValue(forKey: key)
        saveData()
    }
    
    func deleteSessionNote(for date: Date) {
        let key = Calendar.current.startOfDay(for: date)
        sessionNotes.removeValue(forKey: key)
        saveData()
    }
    
    // MÉTODO CORREGIDO: saveData con límites estrictos y manejo de concurrencia mejorado
    private func saveData() {
        // Prevenir llamadas concurrentes múltiples
        guard !isSaving else {
            print("⚠️ SaveData ya en progreso, saltando...")
            return
        }
        
        isSaving = true
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            defer {
                DispatchQueue.main.async {
                    self.isSaving = false
                }
            }
            
            // Limpiar datos antes de guardar
            self.enforceDataLimits()
            
            let encoder = JSONEncoder()
            
            // Función auxiliar para guardar con límite de tamaño
            func saveWithSizeLimit<T: Codable>(_ data: T, key: String, maxSize: Int = self.MAX_USERDEFAULTS_SIZE) {
                do {
                    let encoded = try encoder.encode(data)
                    let dataSize = encoded.count
                    
                    if dataSize <= maxSize {
                        UserDefaults.standard.set(encoded, forKey: key)
                        print("✅ Guardado \(key): \(dataSize) bytes")
                    } else {
                        print("❌ ERROR: \(key) excede límite - \(dataSize) bytes > \(maxSize) bytes")
                        // En caso de exceso, limpiar más agresivamente
                        if key == "WorkoutHistory" {
                            self.emergencyHistoryCleanup()
                            // Intentar guardar de nuevo después de la limpieza
                            if let cleanedEncoded = try? encoder.encode(self.workoutHistory),
                               cleanedEncoded.count <= maxSize {
                                UserDefaults.standard.set(cleanedEncoded, forKey: key)
                                print("✅ Guardado \(key) después de limpieza: \(cleanedEncoded.count) bytes")
                            }
                        }
                    }
                } catch {
                    print("❌ Error codificando \(key): \(error)")
                }
            }
            
            // Guardar cada estructura con límites
            saveWithSizeLimit(self.availableExercises, key: "AvailableExercises", maxSize: 100_000)
            saveWithSizeLimit(self.dailyWorkoutRecords, key: "DailyWorkoutRecords", maxSize: 100_000)
            saveWithSizeLimit(self.workoutHistory, key: "WorkoutHistory", maxSize: 300_000)
            saveWithSizeLimit(self.bodyWeightHistory, key: "BodyWeightHistory", maxSize: 50_000)
            saveWithSizeLimit(self.sessionNotes, key: "SessionNotes", maxSize: 100_000)
            saveWithSizeLimit(self.activeDays, key: "ActiveDays", maxSize: 10_000)
            
            // Guardar configuración simple
            UserDefaults.standard.set(self.restDuration, forKey: "RestDuration")
            
            print("WorkoutViewModel: Guardado completado")
        }
    }
    
    // NUEVO: Aplicar límites estrictos a los datos
    private func enforceDataLimits() {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -MAX_HISTORY_DAYS, to: Date()) ?? Date()
        
        // Limpiar historial antiguo
        let oldHistoryKeys = workoutHistory.keys.filter { $0 < cutoffDate }
        for key in oldHistoryKeys {
            workoutHistory.removeValue(forKey: key)
        }
        
        // Limpiar peso antiguo
        let oldWeightKeys = bodyWeightHistory.keys.filter { $0 < cutoffDate }
        for key in oldWeightKeys {
            bodyWeightHistory.removeValue(forKey: key)
        }
        
        // Limpiar notas antiguas
        let oldNotesKeys = sessionNotes.keys.filter { $0 < cutoffDate }
        for key in oldNotesKeys {
            sessionNotes.removeValue(forKey: key)
        }
        
        // Limitar número de ejercicios únicos
        if availableExercises.count > 50 {
            print("⚠️ Demasiados ejercicios (\(availableExercises.count)), limitando a 50")
            availableExercises = Array(availableExercises.prefix(50))
        }
        
        print("Datos limitados: Historial=\(workoutHistory.count) días, Ejercicios=\(availableExercises.count)")
    }
    
    // NUEVO: Limpieza de emergencia para historial
    private func emergencyHistoryCleanup() {
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        // Mantener solo el último mes
        let recentKeys = workoutHistory.keys.filter { $0 >= oneMonthAgo }
        let recentHistory = Dictionary(uniqueKeysWithValues: recentKeys.map { ($0, workoutHistory[$0]!) })
        
        workoutHistory = recentHistory
        print("🚨 Limpieza de emergencia: Historial reducido a \(workoutHistory.count) días")
    }
    
    // MARK: - Actualizado: completeSet
    func completeSet(for workoutExerciseId: UUID, in day: WorkoutDay) {
        print("🔥 CompleteSet iniciado para: \(workoutExerciseId)")
        
        guard let recordIndex = dailyWorkoutRecords[day]?.firstIndex(where: { $0.id == workoutExerciseId }),
              let baseExercise = getExercise(by: dailyWorkoutRecords[day]![recordIndex].exerciseId) else {
            print("❌ CompleteSet: No se encontró el record o ejercicio")
            return
        }
        
        var record = dailyWorkoutRecords[day]![recordIndex]
        if record.completedSets < baseExercise.totalSets {
            record.completedSets += 1
            record.lastSetCompletedAt = Date()
            dailyWorkoutRecords[day]![recordIndex] = record
            
            print("✅ CompleteSet: Serie completada \(record.completedSets)/\(baseExercise.totalSets)")
            
            recordHistory(for: day)
            checkAndCelebratePersonalRecord(for: baseExercise)
            HapticManager.shared.setCompleted()
            
            if record.completedSets < baseExercise.totalSets {
                print("🔄 CompleteSet: Iniciando timer de \(baseExercise.restDuration)s")
                startTimer(duration: baseExercise.restDuration, isEnabled: isTimerEnabled)
            }
        }
        
        print("🏁 CompleteSet completado")
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
            HapticManager.shared.warning()
        }
    }
    
    func updateBodyWeight(for date: Date, weight: Double) {
        let key = Calendar.current.startOfDay(for: date)
        bodyWeightHistory[key] = weight
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
            
        HapticManager.shared.exerciseDeleted()
        saveData()
    }
    
    // MARK: - TIMER METHODS CORREGIDOS
    
    // MÉTODO CORREGIDO: startTimer
    func startTimer(duration: Int, isEnabled: Bool = true) {
        guard isEnabled else {
            print("WorkoutViewModel: Timer desactivado por configuración")
            return
        }
        
        // Validar duración
        guard duration > 0 && duration <= 600 else {
            print("WorkoutViewModel: Duración de timer inválida: \(duration)")
            return
        }
        
        print("WorkoutViewModel: Iniciando timer con duración: \(duration) segundos")
        
        // CRÍTICO: Detener completamente cualquier timer existente
        stopTimer()
        
        // Esperar un ciclo de run loop para asegurar limpieza
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Verificar que realmente no hay timer activo
            guard self.timer == nil else {
                print("WorkoutViewModel: ERROR - Timer anterior aún existe")
                return
            }
            
            // Configurar estado
            self.timeRemaining = duration
            self.currentTimerDuration = duration
            self.timerActive = true
            
            // Mantener pantalla encendida
            UIApplication.shared.isIdleTimerDisabled = true
            
            // Haptic feedback
            HapticManager.shared.timerStarted()
            
            // Programar notificación
            NotificationManager.shared.scheduleRestNotification(after: TimeInterval(duration))
            
            // Crear timer con mejor gestión de memoria
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] currentTimer in
                DispatchQueue.main.async {
                    guard let self = self else {
                        currentTimer.invalidate()
                        return
                    }
                    
                    // Verificar que este timer sigue siendo el activo
                    guard currentTimer.isValid && self.timer === currentTimer else {
                        currentTimer.invalidate()
                        return
                    }
                    
                    guard self.timerActive else {
                        self.cleanupTimer(currentTimer)
                        return
                    }
                    
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
            
            // Verificar que el timer se creó correctamente
            if self.timer == nil {
                print("WorkoutViewModel: ERROR - No se pudo crear el timer")
                self.timerActive = false
                UIApplication.shared.isIdleTimerDisabled = false
                return
            }
            
            // Iniciar Live Activity
            Task { @MainActor in
                if #available(iOS 16.1, *) {
                    self.liveActivityManager?.startTimerActivity(exerciseName: "Descanso", totalTime: duration)
                }
            }
            
            print("WorkoutViewModel: Timer iniciado exitosamente")
        }
    }
    
    // MÉTODO CORREGIDO: stopTimer
    func stopTimer() {
        print("WorkoutViewModel: Deteniendo timer")
        
        // Cancelar work item si existe
        timerWorkItem?.cancel()
        timerWorkItem = nil
        
        // Limpiar timer
        if let currentTimer = timer {
            cleanupTimer(currentTimer)
        }
        
        // Limpiar estado
        timerActive = false
        
        // Restaurar configuración de pantalla
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        
        // Haptic feedback
        HapticManager.shared.timerStopped()
        
        // Cancelar notificación
        NotificationManager.shared.cancelRestNotification()
        
        // Terminar Live Activity
        Task { @MainActor in
            if #available(iOS 16.1, *) {
                liveActivityManager?.endTimerActivity()
            }
        }
        
        print("WorkoutViewModel: Timer detenido completamente")
    }
    
    // NUEVO MÉTODO: Limpieza segura de timer
    private func cleanupTimer(_ timerToClean: Timer) {
        timerToClean.invalidate()
        if timer === timerToClean {
            timer = nil
        }
    }
    
    // MÉTODO CORREGIDO: completeTimer
    private func completeTimer() {
        print("WorkoutViewModel: Timer completado naturalmente")
        
        // Limpiar timer
        if let currentTimer = timer {
            cleanupTimer(currentTimer)
        }
        
        timerActive = false
        timeRemaining = 0
        
        // Restaurar configuración de pantalla
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        
        // Haptic feedback especial
        HapticManager.shared.timerCompleted()
        
        // Cancelar notificación
        NotificationManager.shared.cancelRestNotification()
        
        // Terminar Live Activity
        Task { @MainActor in
            if #available(iOS 16.1, *) {
                liveActivityManager?.endTimerActivity()
            }
        }
        
        print("WorkoutViewModel: Timer completado y limpiado")
    }
    
    // MÉTODO CORREGIDO: loadData con mejor manejo de errores
    private func loadData() {
        let decoder = JSONDecoder()
        
        // Función auxiliar para cargar datos de forma segura
        func loadSafely<T: Codable>(_ type: T.Type, key: String, fallback: T) -> T {
            guard let data = UserDefaults.standard.data(forKey: key) else {
                print("📁 \(key): No hay datos guardados")
                return fallback
            }
            
            print("📁 Cargando \(key): \(data.count) bytes")
            
            // Verificar tamaño antes de decodificar
            if data.count > MAX_USERDEFAULTS_SIZE * 2 { // Doble del límite es sospechoso
                print("⚠️ \(key) tiene tamaño sospechoso: \(data.count) bytes. Eliminando.")
                UserDefaults.standard.removeObject(forKey: key)
                return fallback
            }
            
            do {
                return try decoder.decode(type, from: data)
            } catch {
                print("❌ Error decodificando \(key): \(error)")
                // Eliminar datos corruptos
                UserDefaults.standard.removeObject(forKey: key)
                return fallback
            }
        }
        
        // Verificar si es primera vez
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        
        if isFirstLaunch {
            setupDefaultData()
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        } else {
            // Cargar datos existentes
            availableExercises = loadSafely([Exercise].self, key: "AvailableExercises", fallback: [])
            dailyWorkoutRecords = loadSafely([WorkoutDay: [WorkoutExercise]].self, key: "DailyWorkoutRecords", fallback: [:])
            workoutHistory = loadSafely([Date: [WorkoutDay: [WorkoutExercise]]].self, key: "WorkoutHistory", fallback: [:])
            bodyWeightHistory = loadSafely([Date: Double].self, key: "BodyWeightHistory", fallback: [:])
            sessionNotes = loadSafely([Date: String].self, key: "SessionNotes", fallback: [:])
            activeDays = loadSafely([WorkoutDay].self, key: "ActiveDays", fallback: WorkoutDay.allCases)
            
            // Cargar configuración simple
            restDuration = UserDefaults.standard.object(forKey: "RestDuration") as? Int ?? 120
        }
        
        // Asegurar estructura básica
        WorkoutDay.allCases.forEach { day in
            if dailyWorkoutRecords[day] == nil {
                dailyWorkoutRecords[day] = []
            }
        }
        
        // Aplicar límites después de cargar
        enforceDataLimits()
        
        print("✅ Datos cargados exitosamente")
        printMemoryInfo()
    }
    
    // NUEVO: Información de memoria
    private func printMemoryInfo() {
        let encoder = JSONEncoder()
        var totalSize = 0
        
        if let data = try? encoder.encode(availableExercises) { totalSize += data.count }
        if let data = try? encoder.encode(dailyWorkoutRecords) { totalSize += data.count }
        if let data = try? encoder.encode(workoutHistory) { totalSize += data.count }
        if let data = try? encoder.encode(bodyWeightHistory) { totalSize += data.count }
        if let data = try? encoder.encode(sessionNotes) { totalSize += data.count }
        
        print("📊 Tamaño total de datos: \(totalSize) bytes (\(totalSize/1024) KB)")
        
        if totalSize > 1_000_000 { // Mayor a 1MB
            print("⚠️ ADVERTENCIA: Datos muy grandes, considerar limpieza")
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
            sfSymbolIcon: "figure.strengthtraining.functional",
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
            sfSymbolIcon: "figure.strengthtraining.functional",
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
            sfSymbolIcon: "figure.rower",
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
            sfSymbolIcon: "figure.strengthtraining.functional",
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
            sfSymbolIcon: "figure.strengthtraining.traditional",
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
            sfSymbolIcon: "figure.strengthtraining.functional",
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
        self.sessionNotes = [:]
        self.activeDays = WorkoutDay.allCases
        userDefaults.removeObject(forKey: "AvailableExercises")
        userDefaults.removeObject(forKey: "DailyWorkoutRecords")
        userDefaults.removeObject(forKey: "WorkoutHistory")
        userDefaults.removeObject(forKey: "BodyWeightHistory")
        userDefaults.removeObject(forKey: "SessionNotes")
        userDefaults.removeObject(forKey: "ActiveDays")
        userDefaults.removeObject(forKey: "RestDuration")
        userDefaults.removeObject(forKey: "HasLaunchedBefore")
    }
    
    // Función para actualizar el estado del timer desde las vistas
    func updateTimerEnabledState(_ isEnabled: Bool) {
        isTimerEnabled = isEnabled
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
    
    // MARK: - Métodos de limpieza de datos
    func clearAllData() {
        print("🚨 WORKOUT_VIEW_MODEL: ¡Se ha llamado a clearAllData! Borrando datos de entrenamiento.")
        print("📍 STACK TRACE: \(Thread.callStackSymbols.prefix(5).joined(separator: "\n"))")
            
        // Limpiar todas las estructuras de datos
        availableExercises.removeAll()
        dailyWorkoutRecords.removeAll()
        workoutHistory.removeAll()
        bodyWeightHistory.removeAll()
        sessionNotes.removeAll()
        activeDays = WorkoutDay.allCases
            
        // Limpiar UserDefaults
        UserDefaults.standard.removeObject(forKey: "AvailableExercises")
        UserDefaults.standard.removeObject(forKey: "DailyWorkoutRecords")
        UserDefaults.standard.removeObject(forKey: "WorkoutHistory")
        UserDefaults.standard.removeObject(forKey: "BodyWeightHistory")
        UserDefaults.standard.removeObject(forKey: "SessionNotes")
        UserDefaults.standard.removeObject(forKey: "ActiveDays")
        UserDefaults.standard.removeObject(forKey: "HasLaunchedBefore")
        
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
            
        if let enc = try? encoder.encode(sessionNotes) {
            info += "- Notas de sesión: \(enc.count) bytes\n"
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
    
    // MARK: - Personal Records Functions
    
    /// Verifica si el peso actual es un nuevo Personal Record y lo celebra
    private func checkAndCelebratePersonalRecord(for exercise: Exercise) {
        let currentWeight = exercise.weight
        let currentPR = exercise.personalRecordWeight ?? 0
            
        // Si el peso actual es mayor que el PR anterior, es un nuevo récord
        if currentWeight > currentPR {
            // Actualizar el Personal Record en el ejercicio
            updatePersonalRecord(for: exercise.id, newWeight: currentWeight)
                
            // Celebrar el nuevo récord
            HapticManager.shared.goalAchieved()
            print("🎉 ¡Nuevo Personal Record! \(exercise.name): \(currentWeight)kg")
        }
    }
    
    /// Actualiza el personal record de un ejercicio
    private func updatePersonalRecord(for exerciseId: UUID, newWeight: Double) {
        if let index = availableExercises.firstIndex(where: { $0.id == exerciseId }) {
            availableExercises[index].personalRecordWeight = newWeight
            saveData()
        }
    }
    
    /// Obtiene los mejores personal records ordenados por peso
    func getTopPersonalRecords(limit: Int = 5) -> [(exerciseName: String, weight: Double)] {
        let exercisesWithPR = availableExercises
            .compactMap { exercise -> (String, Double)? in
                guard let prWeight = exercise.personalRecordWeight, prWeight > 0 else { return nil }
                return (exercise.name, prWeight)
            }
            .sorted { $0.1 > $1.1 } // Ordenar por peso descendente
            .prefix(limit)
        
        return Array(exercisesWithPR).map { (exerciseName: $0.0, weight: $0.1) }
    }
    
    /// Obtiene el personal record de un ejercicio específico
    func getPersonalRecord(for exerciseId: UUID) -> Double? {
        return availableExercises.first(where: { $0.id == exerciseId })?.personalRecordWeight
    }
}
