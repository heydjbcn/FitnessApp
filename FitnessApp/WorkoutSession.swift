//
//  WorkoutSession.swift
//  FitnessApp
//
//  Created by Assistant on Date
//

import Foundation
import CoreData

/// Core Data entity extension for WorkoutSession
/// This file provides the Core Data model extensions and helper methods

// The actual Core Data entity is defined in the .xcdatamodeld file
// This extension provides helper methods and computed properties

extension WorkoutSession {
    
    // MARK: - Computed Properties
    
    /// Get completed exercises as a typed array
    var completedExercisesArray: [CompletedExercise] {
        let set = completedExercises as? Set<CompletedExercise> ?? []
        return Array(set).sorted { ($0.setNumber) < ($1.setNumber) }
    }
    
    /// Check if the session is completed
    var isSessionCompleted: Bool {
        return completedAt != nil
    }
    
    /// Get the duration of the session in seconds
    var sessionDuration: TimeInterval {
        guard let createdAt = createdAt else { return 0 }
        let endTime = completedAt ?? Date()
        return endTime.timeIntervalSince(createdAt)
    }
    
    /// Get formatted duration string
    var formattedDuration: String {
        let duration = sessionDuration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Get total sets completed in this session
    var totalCompletedSets: Int {
        return completedExercisesArray.count // Cada CompletedExercise representa una serie completada
    }
    
    /// Get workout day as enum
    var workoutDayEnum: WorkoutDay? {
        guard let workoutDay = workoutDay else { return nil }
        return WorkoutDay(rawValue: workoutDay)
    }
    
    // MARK: - Helper Methods
    
    /// Mark session as completed
    func markAsCompleted() {
        completedAt = Date()
        isCompleted = true
        duration = Int32(sessionDuration)
    }
    
    /// Add a note to the session
    func addNote(_ note: String) {
        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            notes = nil
        } else {
            notes = note
        }
    }
    
    /// Update body weight for this session
    func updateBodyWeight(_ weight: Double) {
        bodyWeight = weight
    }
    
    /// Get all unique exercises in this session
    var uniqueExercises: [ExerciseEntity] {
        let exercises = completedExercisesArray.compactMap { $0.exercise }
        var uniqueSet = Set<ExerciseEntity>()
        var result: [ExerciseEntity] = []
        
        for exercise in exercises {
            if !uniqueSet.contains(exercise) {
                uniqueSet.insert(exercise)
                result.append(exercise)
            }
        }
        
        return result
    }
    
    /// Check if session contains a specific exercise
    func containsExercise(withId exerciseId: UUID) -> Bool {
        return completedExercisesArray.contains { completedExercise in
            completedExercise.exercise?.id == exerciseId
        }
    }
    
    /// Get completed exercise for specific exercise ID
    func getCompletedExercise(for exerciseId: UUID) -> CompletedExercise? {
        return completedExercisesArray.first { completedExercise in
            completedExercise.exercise?.id == exerciseId
        }
    }
    
    /// Calculate estimated calories burned (rough estimation)
    var estimatedCaloriesBurned: Int {
        let baseDuration = sessionDuration / 60 // in minutes
        let sets = totalCompletedSets
        
        // Rough calculation: 5 calories per minute + 3 calories per set
        let estimated = Int(baseDuration * 5) + (sets * 3)
        return max(estimated, 0)
    }
    
    /// Get session summary
    var sessionSummary: String {
        let exerciseCount = uniqueExercises.count
        let setsCount = totalCompletedSets
        let duration = formattedDuration
        
        return "\(exerciseCount) ejercicios, \(setsCount) series, \(duration)"
    }
}

// MARK: - Static Factory Methods
extension WorkoutSession {
    
    /// Create a new workout session
    static func createSession(
        in context: NSManagedObjectContext,
        date: Date = Date(),
        workoutDay: WorkoutDay,
        bodyWeight: Double = 0
    ) -> WorkoutSession {
        let session = WorkoutSession(context: context)
        session.id = UUID()
        session.date = date
        session.workoutDay = workoutDay.rawValue
        session.bodyWeight = bodyWeight
        session.createdAt = Date()
        session.isCompleted = false
        session.duration = 0
        return session
    }
}

// MARK: - Query Methods
extension WorkoutSession {
    
    /// Fetch all sessions for a specific date
    static func fetchSessions(for date: Date, in context: NSManagedObjectContext) -> [WorkoutSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WorkoutSession.date, ascending: false)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching sessions for date: \(error)")
            return []
        }
    }
    
    /// Fetch completed sessions only
    
    /// Fetch sessions within a date range
    static func fetchSessions(from startDate: Date, to endDate: Date, in context: NSManagedObjectContext) -> [WorkoutSession] {
        let request: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WorkoutSession.date, ascending: false)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching sessions for date range: \(error)")
            return []
        }
    }
    /// Fetch completed sessions only
    static func fetchCompletedSessions(in context: NSManagedObjectContext) -> [WorkoutSession] {
        let request: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        request.predicate = NSPredicate(format: "completedAt != nil")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WorkoutSession.completedAt, ascending: false)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching completed sessions: \(error)")
            return []
        }
    }
    
    /// Count total sessions
    static func countSessions(in context: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting sessions: \(error)")
            return 0
        }
    }
    
    /// Count completed sessions
    static func countCompletedSessions(in context: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        request.predicate = NSPredicate(format: "completedAt != nil")
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting completed sessions: \(error)")
            return 0
        }
    }
}

// MARK: - Statistics Methods
extension WorkoutSession {
    
    /// Get weekly statistics for sessions
    static func getWeeklyStats(for date: Date, in context: NSManagedObjectContext) -> (sessions: Int, totalSets: Int, totalDuration: TimeInterval) {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return (0, 0, 0)
        }
        
        let sessions = fetchSessions(from: weekInterval.start, to: weekInterval.end, in: context)
        
        let totalSets = sessions.reduce(0) { sum, session in
            sum + session.totalCompletedSets
        }
        
        let totalDuration = sessions.reduce(0) { sum, session in
            sum + session.sessionDuration
        }
        
        return (sessions.count, totalSets, totalDuration)
    }
    
    /// Get monthly statistics for sessions
    static func getMonthlyStats(for date: Date, in context: NSManagedObjectContext) -> (sessions: Int, totalSets: Int, totalDuration: TimeInterval) {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return (0, 0, 0)
        }
        
        let sessions = fetchSessions(from: monthInterval.start, to: monthInterval.end, in: context)
        
        let totalSets = sessions.reduce(0) { sum, session in
            sum + session.totalCompletedSets
        }
        
        let totalDuration = sessions.reduce(0) { sum, session in
            sum + session.sessionDuration
        }
        
        return (sessions.count, totalSets, totalDuration)
    }
}

// MARK: - Export Methods
extension WorkoutSession {
    
    /// Convert to dictionary for export
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        dict["id"] = id?.uuidString
        dict["date"] = date?.timeIntervalSince1970
        dict["workoutDay"] = workoutDay
        dict["bodyWeight"] = bodyWeight
        dict["notes"] = notes
        dict["isCompleted"] = isCompleted
        dict["createdAt"] = createdAt?.timeIntervalSince1970
        dict["completedAt"] = completedAt?.timeIntervalSince1970
        dict["duration"] = duration
        
        // Add completed exercises
        let exercisesDicts = completedExercisesArray.compactMap { exercise in
            exercise.toDictionary()
        }
        dict["completedExercises"] = exercisesDicts
        
        return dict
    }
}

// MARK: - CompletedExercise Extension
extension CompletedExercise {
    
    /// Convert to dictionary for export
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        dict["id"] = id?.uuidString
        dict["setNumber"] = setNumber
        dict["weight"] = weight
        dict["reps"] = reps
        dict["completedSets"] = 1 // Cada CompletedExercise representa 1 serie completada
        dict["isCompleted"] = isCompleted
        dict["completedAt"] = completedAt?.timeIntervalSince1970
        dict["exerciseId"] = exercise?.id?.uuidString
        
        return dict
    }
}
