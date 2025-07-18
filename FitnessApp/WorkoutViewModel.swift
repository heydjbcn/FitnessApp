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
    @Published var exercises: [WorkoutDay: [Exercise]] = [:]
    @Published var workoutHistory: [Date: [WorkoutDay: [Exercise]]] = [:]
    @Published var bodyWeightHistory: [Date: Double] = [:]
    @Published var timerActive = false
    @Published var timeRemaining = 120
    @Published var restDuration = 120 // Tiempo de descanso personalizable (por defecto 2 minutos)

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
        WorkoutDay.allCases.forEach { exercises[$0] = [] }
        loadData()
    }
    
    private func recordHistory(for day: WorkoutDay) {
        let key = Calendar.current.startOfDay(for: Date())
        var historyForToday = workoutHistory[key] ?? [:]
        historyForToday[day] = self.exercises[day]
        workoutHistory[key] = historyForToday
        saveData()
    }

    func exercisesForDate(_ date: Date) -> [WorkoutDay: [Exercise]]? {
        let key = Calendar.current.startOfDay(for: date)
        return workoutHistory[key]
    }
    
    private func saveData() {
        DispatchQueue.global(qos: .background).async {
            let encoder = JSONEncoder()
            if let enc = try? encoder.encode(self.exercises) { UserDefaults.standard.set(enc, forKey: "WorkoutData") }
            if let encH = try? encoder.encode(self.workoutHistory) { UserDefaults.standard.set(encH, forKey: "WorkoutHistory") }
            if let encW = try? encoder.encode(self.bodyWeightHistory) { UserDefaults.standard.set(encW, forKey: "BodyWeightHistory") }
            if let encD = try? encoder.encode(self.activeDays) { UserDefaults.standard.set(encD, forKey: "ActiveDays") }
            UserDefaults.standard.set(self.restDuration, forKey: "RestDuration")
        }
    }
    
    func completeSet(for day: WorkoutDay, exerciseId: UUID) {
        guard let i = exercises[day]?.firstIndex(where: { $0.id == exerciseId }) else { return }
        var ex = exercises[day]![i]; if ex.completedSets < ex.totalSets {
            ex.completedSets += 1; ex.lastSetCompletedAt = Date(); exercises[day]![i] = ex
            recordHistory(for: day)
            if ex.completedSets < ex.totalSets { startRestTimer() }
        }
    }
    
    func addExercise(to day: WorkoutDay, name: String, reps: Int, weight: Double, sets: Int, info: String, imageData: Data?) { let ex = Exercise(name: name, repetitions: reps, weight: weight, totalSets: sets, info: info, imageData: imageData); exercises[day]?.append(ex); recordHistory(for: day) }
    func toggleDay(_ day: WorkoutDay) { if let idx = activeDays.firstIndex(of: day) { activeDays.remove(at: idx) } else { activeDays.append(day); activeDays.sort { WorkoutDay.allCases.firstIndex(of: $0)! < WorkoutDay.allCases.firstIndex(of: $1)! } }; saveData() }
    func removeExercise(from day: WorkoutDay, at index: Int) { exercises[day]?.remove(at: index); recordHistory(for: day) }
    func undoLastSet(for day: WorkoutDay, exerciseId: UUID) { guard let i = exercises[day]?.firstIndex(where: { $0.id == exerciseId }) else { return }; var ex = exercises[day]![i]; if ex.completedSets > 0 { ex.completedSets -= 1; if ex.completedSets == 0 { ex.lastSetCompletedAt = nil }; exercises[day]![i] = ex; recordHistory(for: day) } }
    func updateBodyWeight(for date: Date, weight: Double) { let key = Calendar.current.startOfDay(for: date); bodyWeightHistory[key] = weight; saveData() }
    func bodyWeightForDate(_ date: Date) -> Double? { let key = Calendar.current.startOfDay(for: date); return bodyWeightHistory[key] }
    func progressForDay(_ day: WorkoutDay) -> Double { let arr = exercises[day] ?? []; let total = arr.reduce(0) { $0 + $1.totalSets }; let done = arr.reduce(0) { $0 + $1.completedSets }; return total > 0 ? Double(done) / Double(total) : 0 }
    func startRestTimer() { 
        timerActive = true
        timeRemaining = restDuration
        
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
        timeRemaining = restDuration
        
        // Terminar Live Activity
        Task { @MainActor in
            if #available(iOS 16.1, *) {
                liveActivityManager?.endTimerActivity()
            }
        }
    }
    private func loadData() { let d = JSONDecoder(); if let data = userDefaults.data(forKey: "WorkoutData"), let dec = try? d.decode([WorkoutDay: [Exercise]].self, from: data) { exercises = dec }; if let data = userDefaults.data(forKey: "WorkoutHistory"), let dec = try? d.decode([Date: [WorkoutDay: [Exercise]]].self, from: data) { workoutHistory = dec }; if let data = userDefaults.data(forKey: "BodyWeightHistory"), let dec = try? d.decode([Date: Double].self, from: data) { bodyWeightHistory = dec }; if let data = userDefaults.data(forKey: "ActiveDays"), let dec = try? d.decode([WorkoutDay].self, from: data) { activeDays = dec }; restDuration = userDefaults.object(forKey: "RestDuration") as? Int ?? 120 }
    func resetAllData() { self.exercises = [:]; self.workoutHistory = [:]; self.bodyWeightHistory = [:]; self.activeDays = WorkoutDay.allCases; WorkoutDay.allCases.forEach { exercises[$0] = [] }; userDefaults.removeObject(forKey: "WorkoutData"); userDefaults.removeObject(forKey: "WorkoutHistory"); userDefaults.removeObject(forKey: "BodyWeightHistory"); userDefaults.removeObject(forKey: "ActiveDays"); }
    
    // MARK: - Weekly Statistics
    
    func weeklyProgress() -> Double {
        let totalSets = activeDays.reduce(0) { total, day in
            total + (exercises[day]?.reduce(0) { $0 + $1.totalSets } ?? 0)
        }
        let completedSets = activeDays.reduce(0) { total, day in
            total + (exercises[day]?.reduce(0) { $0 + $1.completedSets } ?? 0)
        }
        return totalSets > 0 ? Double(completedSets) / Double(totalSets) : 0
    }
    
    func weeklyCompletedSets() -> Int {
        return activeDays.reduce(0) { total, day in
            total + (exercises[day]?.reduce(0) { $0 + $1.completedSets } ?? 0)
        }
    }
    
    func weeklyTotalSets() -> Int {
        return activeDays.reduce(0) { total, day in
            total + (exercises[day]?.reduce(0) { $0 + $1.totalSets } ?? 0)
        }
    }
    
    func weeklyExercisesSummary() -> [(day: WorkoutDay, exercises: [Exercise])] {
        return WorkoutDay.allCases.compactMap { day -> (day: WorkoutDay, exercises: [Exercise])? in
            guard let dayExercises = exercises[day], !dayExercises.isEmpty else { 
                return nil 
            }
            return (day: day, exercises: dayExercises)
        }.sorted { (d1: (day: WorkoutDay, exercises: [Exercise]), d2: (day: WorkoutDay, exercises: [Exercise])) in
            WorkoutDay.allCases.firstIndex(of: d1.day)! < WorkoutDay.allCases.firstIndex(of: d2.day)!
        }
    }
    
    func consecutiveWorkoutDays() -> Int {
        let _ = workoutHistory.keys.sorted(by: >)
        var consecutiveDays = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        
        for _ in 0..<7 { // Check last 7 days
            if let dayHistory = workoutHistory[currentDate] {
                let hasCompletedWorkout = dayHistory.values.contains { exercises in
                    exercises.contains { $0.completedSets > 0 }
                }
                if hasCompletedWorkout {
                    consecutiveDays += 1
                } else {
                    break
                }
            } else {
                break
            }
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return consecutiveDays
    }
    
    func bestWorkoutDay() -> WorkoutDay? {
        var dayProgress: [WorkoutDay: Double] = [:]
        
        for day in activeDays {
            dayProgress[day] = progressForDay(day)
        }
        
        return dayProgress.max(by: { $0.value < $1.value })?.key
    }
    
    func totalUniqueExercises() -> Int {
        var uniqueExercises = Set<String>()
        for day in activeDays {
            exercises[day]?.forEach { exercise in
                uniqueExercises.insert(exercise.name)
            }
        }
        return uniqueExercises.count
    }
    
    func estimatedWeeklyWorkoutTime() -> Int {
        // Estimate: 1 minute per set + 2 minutes rest between sets
        let totalSets = weeklyTotalSets()
        return totalSets > 0 ? totalSets * 3 : 0 // 3 minutes per set (1 for exercise + 2 for rest)
    }
    
    // MARK: - Exercise Management Methods
    
    func addExercise(_ exercise: Exercise, to day: WorkoutDay) {
        if exercises[day] == nil {
            exercises[day] = []
        }
        exercises[day]?.append(exercise)
        saveData()
    }
    
    func removeExercise(_ exercise: Exercise, from day: WorkoutDay) {
        exercises[day]?.removeAll { $0.id == exercise.id }
        saveData()
    }
    
    func removeExercise(withId id: UUID, from day: WorkoutDay) {
        exercises[day]?.removeAll { $0.id == id }
        saveData()
    }
    
    func updateExercise(_ updatedExercise: Exercise, in day: WorkoutDay) {
        if let index = exercises[day]?.firstIndex(where: { $0.id == updatedExercise.id }) {
            exercises[day]?[index] = updatedExercise
            saveData()
        }
    }
    
    // MARK: - Set Completion Methods
    
    func toggleSetCompletion(exercise: Exercise, setIndex: Int) {
        guard let day = findDayForExercise(exercise),
              let exerciseIndex = exercises[day]?.firstIndex(where: { $0.id == exercise.id }) else {
            return
        }
        
        var updatedExercise = exercises[day]![exerciseIndex]
        
        if setIndex == updatedExercise.completedSets {
            // Completar la siguiente serie
            updatedExercise.completedSets += 1
        } else if setIndex == updatedExercise.completedSets - 1 {
            // Desmarcar la última serie completada
            updatedExercise.completedSets -= 1
        }
        
        exercises[day]![exerciseIndex] = updatedExercise
        saveData()
        
        // Registrar progreso en el historial
        recordHistory(for: day)
    }
    
    private func findDayForExercise(_ exercise: Exercise) -> WorkoutDay? {
        for day in WorkoutDay.allCases {
            if exercises[day]?.contains(where: { $0.id == exercise.id }) == true {
                return day
            }
        }
        return nil
    }
    
    // MARK: - Timer Methods
    
    func startTimer(duration: Int) {
        stopTimer() // Detener cualquier timer existente
        timeRemaining = duration
        timerActive = true
        
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
        
        // Vibración cuando el timer termina
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        // Notificación local si la app está en background
        scheduleTimerCompletionNotification()
    }
    
    private func scheduleTimerCompletionNotification() {
        // Esta función podría implementar notificaciones locales
        // Por ahora solo hacemos vibración
    }
}
