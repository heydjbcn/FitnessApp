//
//  WorkoutExercise.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 18/7/25.
//

import Foundation
import SwiftUI

struct WorkoutExercise: Identifiable, Codable, Equatable {
    var id = UUID()
    var exerciseId: UUID
    
    var exerciseName: String
    var repetitions: Int
    var weight: Double
    var totalSets: Int
    var info: String
    var imageData: Data?
    var restDuration: Int
    var sfSymbolIcon: String?
    var iconColor: String
    var segundos: Int
    var rir: Int
    
    var completedSets: Int = 0
    var lastSetCompletedAt: Date?

    // MARK: - Initializers
    
    /// Inicializador completo con todos los parámetros
    init(id: UUID = UUID(),
         exerciseId: UUID,
         exerciseName: String,
         repetitions: Int,
         weight: Double,
         totalSets: Int,
         info: String,
         imageData: Data? = nil,
         restDuration: Int,
         sfSymbolIcon: String? = nil,
         iconColor: String = "blue",
         segundos: Int = 0,
         rir: Int = 0,
         completedSets: Int = 0,
         lastSetCompletedAt: Date? = nil) {
        
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.repetitions = repetitions
        self.weight = weight
        self.totalSets = totalSets
        self.info = info
        self.imageData = imageData
        self.restDuration = restDuration
        self.sfSymbolIcon = sfSymbolIcon
        self.iconColor = iconColor
        self.segundos = segundos
        self.rir = rir
        self.completedSets = completedSets
        self.lastSetCompletedAt = lastSetCompletedAt
    }

    /// Inicializador desde un Exercise
    init(from exercise: Exercise) {
        self.id = UUID()
        self.exerciseId = exercise.id
        self.exerciseName = exercise.name
        self.repetitions = exercise.repetitions
        self.weight = exercise.weight
        self.totalSets = exercise.totalSets
        self.info = exercise.info
        self.imageData = exercise.imageData
        self.restDuration = exercise.restDuration
        self.sfSymbolIcon = exercise.sfSymbolIcon
        self.iconColor = exercise.iconColor
        self.segundos = exercise.segundos
        self.rir = exercise.rir
        self.completedSets = 0
        self.lastSetCompletedAt = nil
    }
    
    /// Inicializador simplificado para compatibilidad con el ViewModel
    init(id: UUID = UUID(),
         exerciseId: UUID,
         completedSets: Int = 0,
         lastSetCompletedAt: Date? = nil) {
        
        self.id = id
        self.exerciseId = exerciseId
        self.completedSets = completedSets
        self.lastSetCompletedAt = lastSetCompletedAt
        
        // Valores por defecto para compatibilidad
        self.exerciseName = "Ejercicio"
        self.repetitions = 10
        self.weight = 0
        self.totalSets = 3
        self.info = ""
        self.imageData = nil
        self.restDuration = 60
        self.sfSymbolIcon = "dumbbell.fill"
        self.iconColor = "blue"
        self.segundos = 0
        self.rir = 0
    }
    
    // MARK: - Helper Methods
    
    /// Verifica si el ejercicio está completado
    var isCompleted: Bool {
        return completedSets >= totalSets
    }
    
    /// Obtiene el progreso como porcentaje (0.0 - 1.0)
    var progressPercentage: Double {
        guard totalSets > 0 else { return 0.0 }
        return Double(completedSets) / Double(totalSets)
    }
    
    /// Obtiene el progreso como porcentaje entero (0 - 100)
    var progressPercent: Int {
        return Int(progressPercentage * 100)
    }
    
    /// Obtiene las series restantes
    var remainingSets: Int {
        return max(0, totalSets - completedSets)
    }
    
    /// Verifica si hay series completadas
    var hasCompletedSets: Bool {
        return completedSets > 0
    }
    
    /// Obtiene una descripción del progreso
    var progressDescription: String {
        return "\(completedSets)/\(totalSets) series"
    }
    
    /// Obtiene una descripción completa del ejercicio
    var fullDescription: String {
        var parts: [String] = []
        
        if repetitions > 0 {
            parts.append("\(repetitions) reps")
        }
        
        if weight > 0 {
            parts.append("\(String(format: "%.1f", weight)) kg")
        }
        
        if segundos > 0 {
            parts.append("\(segundos)s")
        }
        
        parts.append(progressDescription)
        
        return parts.joined(separator: " • ")
    }
    
    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId
        case exerciseName
        case repetitions
        case weight
        case totalSets
        case info
        case imageData
        case restDuration
        case sfSymbolIcon
        case iconColor
        case segundos
        case rir
        case completedSets
        case lastSetCompletedAt
    }
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: WorkoutExercise, rhs: WorkoutExercise) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Mutating Methods
    
    /// Completa una serie
    mutating func completeSet() {
        if completedSets < totalSets {
            completedSets += 1
            lastSetCompletedAt = Date()
        }
    }
    
    /// Deshace la última serie completada
    mutating func undoLastSet() {
        if completedSets > 0 {
            completedSets -= 1
            if completedSets == 0 {
                lastSetCompletedAt = nil
            }
        }
    }
    
    /// Resetea el progreso del ejercicio
    mutating func resetProgress() {
        completedSets = 0
        lastSetCompletedAt = nil
    }
    
    /// Actualiza los parámetros del ejercicio desde un Exercise
    mutating func updateFrom(_ exercise: Exercise) {
        self.exerciseName = exercise.name
        self.repetitions = exercise.repetitions
        self.weight = exercise.weight
        self.totalSets = exercise.totalSets
        self.info = exercise.info
        self.imageData = exercise.imageData
        self.restDuration = exercise.restDuration
        self.sfSymbolIcon = exercise.sfSymbolIcon
        self.iconColor = exercise.iconColor
        self.segundos = exercise.segundos
        self.rir = exercise.rir
        
        // Nota: No actualizamos completedSets ni lastSetCompletedAt
        // para preservar el progreso actual
    }
    
    /// Actualiza desde un Exercise manteniendo el progreso
    mutating func syncWith(_ exercise: Exercise) {
        updateFrom(exercise)
    }
}

// MARK: - Extensions

extension WorkoutExercise {
    
    /// Convierte a un Exercise (para compatibilidad)
    func toExercise() -> Exercise {
        return Exercise(
            id: exerciseId,
            name: exerciseName,
            repetitions: repetitions,
            weight: weight,
            totalSets: totalSets,
            info: info,
            imageData: imageData,
            restDuration: restDuration,
            sfSymbolIcon: sfSymbolIcon,
            iconColor: iconColor,
            segundos: segundos,
            rir: rir
        )
    }
    
    /// Obtiene el color del icono como Color de SwiftUI
    var iconColorAsColor: Color {
        return AppColors.accentRed // Usar el color principal de la app
    }
    
    /// Obtiene un resumen para mostrar en la UI
    var displaySummary: String {
        var summary = exerciseName
        
        if weight > 0 {
            summary += " • \(String(format: "%.1f", weight))kg"
        }
        
        if repetitions > 0 {
            summary += " • \(repetitions) reps"
        }
        
        if segundos > 0 {
            summary += " • \(segundos)s"
        }
        
        return summary
    }
    
    /// Calcula las calorías estimadas quemadas por serie
    var estimatedCaloriesPerSet: Double {
        let baseCalories = 5.0 // Calorías base por serie
        let weightMultiplier = weight * 0.01 // Factor de peso
        let repsMultiplier = Double(repetitions) * 0.1 // Factor de repeticiones
        
        return baseCalories + weightMultiplier + repsMultiplier
    }
    
    /// Calorías totales estimadas para el ejercicio completo
    var totalEstimatedCalories: Double {
        return estimatedCaloriesPerSet * Double(completedSets)
    }
    
    /// Tiempo estimado para completar el ejercicio (incluyendo descansos)
    var estimatedDuration: TimeInterval {
        let setDuration: TimeInterval = 60 // 1 minuto por serie
        let restTime = Double(restDuration) * Double(max(0, completedSets - 1)) // Descanso entre series
        return Double(completedSets) * setDuration + restTime
    }
    
    /// Fecha de la última actividad
    var lastActivityDate: Date? {
        return lastSetCompletedAt
    }
    
    /// Determina si el ejercicio fue completado hoy
    var isCompletedToday: Bool {
        guard let lastCompleted = lastSetCompletedAt else { return false }
        return Calendar.current.isDateInToday(lastCompleted)
    }
    
    /// Obtiene el estado del ejercicio como string
    var statusDescription: String {
        if completedSets == 0 {
            return "Sin empezar"
        } else if isCompleted {
            return "Completado"
        } else {
            return "En progreso"
        }
    }
}

// MARK: - Array Extensions

extension Array where Element == WorkoutExercise {
    
    /// Obtiene el progreso total de un array de WorkoutExercise
    var totalProgress: Double {
        guard !isEmpty else { return 0.0 }
        
        let totalSets = reduce(0) { $0 + $1.totalSets }
        let completedSets = reduce(0) { $0 + $1.completedSets }
        
        return totalSets > 0 ? Double(completedSets) / Double(totalSets) : 0.0
    }
    
    /// Obtiene el número total de series completadas
    var totalCompletedSets: Int {
        return reduce(0) { $0 + $1.completedSets }
    }
    
    /// Obtiene el número total de series planificadas
    var totalPlannedSets: Int {
        return reduce(0) { $0 + $1.totalSets }
    }
    
    /// Verifica si todos los ejercicios están completados
    var allCompleted: Bool {
        return !isEmpty && allSatisfy { $0.isCompleted }
    }
    
    /// Obtiene los ejercicios completados
    var completed: [WorkoutExercise] {
        return filter { $0.isCompleted }
    }
    
    /// Obtiene los ejercicios pendientes
    var pending: [WorkoutExercise] {
        return filter { !$0.isCompleted }
    }
    
    /// Obtiene los ejercicios con progreso parcial
    var inProgress: [WorkoutExercise] {
        return filter { $0.hasCompletedSets && !$0.isCompleted }
    }
    
    /// Obtiene las calorías totales estimadas
    var totalEstimatedCalories: Double {
        return reduce(0) { $0 + $1.totalEstimatedCalories }
    }
    
    /// Obtiene la duración total estimada
    var totalEstimatedDuration: TimeInterval {
        return reduce(0) { $0 + $1.estimatedDuration }
    }
    
    /// Obtiene un resumen del entrenamiento
    var workoutSummary: String {
        let completedCount = completed.count
        let totalCount = count
        let completedSetsCount = totalCompletedSets
        let totalSetsCount = totalPlannedSets
        
        return "\(completedCount)/\(totalCount) ejercicios • \(completedSetsCount)/\(totalSetsCount) series"
    }
    
    /// Ordena por prioridad (incompletos primero, luego por progreso)
    var sortedByPriority: [WorkoutExercise] {
        return sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted // Incompletos primero
            }
            return lhs.progressPercentage < rhs.progressPercentage // Menor progreso primero
        }
    }
    
    /// Filtra ejercicios completados hoy
    var completedToday: [WorkoutExercise] {
        return filter { $0.isCompletedToday }
    }
    
    /// Obtiene estadísticas del entrenamiento
    var workoutStats: (completed: Int, inProgress: Int, pending: Int, totalSets: Int, completedSets: Int) {
        return (
            completed: completed.count,
            inProgress: inProgress.count,
            pending: pending.count,
            totalSets: totalPlannedSets,
            completedSets: totalCompletedSets
        )
    }
}
