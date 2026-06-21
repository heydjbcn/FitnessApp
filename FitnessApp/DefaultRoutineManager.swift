//
//  DefaultRoutineManager.swift
//  FitnessApp
//
//  Maneja las rutinas por defecto de la aplicación
//

import Combine
import Foundation
import SwiftUI

@MainActor
class DefaultRoutineManager: ObservableObject {
    static let shared = DefaultRoutineManager()
    
    private init() {}
    
    /// Rutina por defecto que se carga automáticamente en la aplicación
    func loadDefaultRoutine(into viewModel: WorkoutViewModel) {
        // Limpiar rutinas existentes antes de cargar la nueva
        viewModel.dailyWorkoutRecords.removeAll()
        
        // Cargar rutina del Lunes (Día 1)
        loadMondayRoutine(into: viewModel)
        
        // Cargar rutina del Miércoles (Día 2)
        loadWednesdayRoutine(into: viewModel)
        
        // Cargar rutina del Viernes (Día 3)
        loadFridayRoutine(into: viewModel)
        
        print("✅ Rutina por defecto cargada exitosamente")
    }
    
    /// Verifica si ya existe una rutina cargada
    func hasExistingRoutine(in viewModel: WorkoutViewModel) -> Bool {
        return !viewModel.dailyWorkoutRecords.isEmpty
    }
    
    /// Carga la rutina solo si no existe una previamente
    func loadDefaultRoutineIfNeeded(into viewModel: WorkoutViewModel) {
        if !hasExistingRoutine(in: viewModel) {
            loadDefaultRoutine(into: viewModel)
        }
    }
}

// MARK: - Rutinas específicas por día

extension DefaultRoutineManager {
    
    /// Lunes: Día 1 - Foco en piernas e isquiotibiales
    private func loadMondayRoutine(into viewModel: WorkoutViewModel) {
        let mondayExercises = [
            createExercise(
                name: "HIP THRUST EN MÁQUINA",
                muscleGroup: "Piernas",
                type: "Máquina",
                sets: 4,
                reps: 15,
                weight: 30.0,
                icon: "figure.strengthtraining.traditional",
                color: "red"
            ),
            createExercise(
                name: "ABDUCCIÓN DE CADERA EN MÁQUINA",
                muscleGroup: "Piernas",
                type: "Máquina",
                sets: 4,
                reps: 15,
                weight: 25.0,
                icon: "figure.strengthtraining.traditional",
                color: "red"
            ),
            createExercise(
                name: "PESO MUERTO CON PESA RUSA",
                muscleGroup: "Isquiotibiales",
                type: "Peso libre",
                sets: 4,
                reps: 15,
                weight: 12.0,
                icon: "dumbbell.fill",
                color: "orange"
            ),
            createExercise(
                name: "CURL FEMORAL TUMBADO",
                muscleGroup: "Isquiotibiales",
                type: "Máquina",
                sets: 4,
                reps: 15,
                weight: 20.0,
                icon: "figure.strengthtraining.traditional",
                color: "orange"
            ),
            createExercise(
                name: "CURL FEMORAL SENTADO",
                muscleGroup: "Isquiotibiales",
                type: "Máquina",
                sets: 4,
                reps: 15,
                weight: 20.0,
                icon: "figure.strengthtraining.traditional",
                color: "orange"
            )
        ]
        
        addExercisesToDay(.monday, exercises: mondayExercises, viewModel: viewModel)
    }
    
    /// Miércoles: Día 2 - Foco en dorsales y hombros
    private func loadWednesdayRoutine(into viewModel: WorkoutViewModel) {
        let wednesdayExercises = [
            createExercise(
                name: "DOMINADAS EN MÁQUINA CON AYUDA",
                muscleGroup: "Dorsales",
                type: "Máquina",
                sets: 4,
                reps: 15,
                weight: 30.0,
                icon: "figure.strengthtraining.traditional",
                color: "blue"
            ),
            createExercise(
                name: "ADUCCIÓN DE CODOS EN MÁQUINA",
                muscleGroup: "Dorsales",
                type: "Máquina",
                sets: 4,
                reps: 15,
                weight: 25.0,
                icon: "figure.strengthtraining.traditional",
                color: "blue"
            ),
            createExercise(
                name: "REMO UNILATERAL CON APOYO EN EL PECHO",
                muscleGroup: "Dorsales",
                type: "Máquina",
                sets: 4,
                reps: 15,
                weight: 10.0,
                icon: "figure.strengthtraining.traditional",
                color: "blue"
            ),
            createExercise(
                name: "VUELO POSTERIOR DE HOMBRO EN MÁQUINA",
                muscleGroup: "Hombros y Cuello",
                type: "Máquina",
                sets: 4,
                reps: 15,
                weight: 8.0,
                icon: "figure.strengthtraining.traditional",
                color: "purple"
            ),
            createExercise(
                name: "ELEVACIÓN LATERAL SENTADO MANCUERNA",
                muscleGroup: "Hombros y Cuello",
                type: "Peso libre",
                sets: 4,
                reps: 15,
                weight: 4.0,
                icon: "dumbbell.fill",
                color: "purple"
            ),
            createExercise(
                name: "ELEVACIÓN FRONTAL DE PIE MANCUERNA",
                muscleGroup: "Hombros y Cuello",
                type: "Peso libre",
                sets: 4,
                reps: 15,
                weight: 3.0,
                icon: "dumbbell.fill",
                color: "purple"
            )
        ]
        
        addExercisesToDay(.wednesday, exercises: wednesdayExercises, viewModel: viewModel)
    }
    
    /// Viernes: Día 3 - Foco en piernas (variado)
    private func loadFridayRoutine(into viewModel: WorkoutViewModel) {
        let fridayExercises = [
            createExercise(
                name: "HIP THRUST EN MÁQUINA",
                muscleGroup: "Piernas",
                type: "Máquina",
                sets: 4,
                reps: 15,
                weight: 30.0,
                icon: "figure.strengthtraining.traditional",
                color: "red"
            ),
            createExercise(
                name: "SENTADILLA HACK",
                muscleGroup: "Piernas",
                type: "Máquina",
                sets: 4,
                reps: 15,
                weight: 25.0,
                icon: "figure.strengthtraining.traditional",
                color: "red"
            ),
            createExercise(
                name: "ZANCADA PIES ESTÁTICOS EN SUELO",
                muscleGroup: "Piernas",
                type: "Peso corporal",
                sets: 4,
                reps: 15,
                weight: 0.0, // Peso corporal
                icon: "figure.walk",
                color: "green"
            ),
            createExercise(
                name: "PRENSA DE PIERNA UNILATERAL",
                muscleGroup: "Piernas",
                type: "Máquina",
                sets: 4,
                reps: 15,
                weight: 15.0,
                icon: "figure.strengthtraining.traditional",
                color: "red"
            ),
            createExercise(
                name: "EXTENSIÓN RODILLA EN MÁQUINA SILLA",
                muscleGroup: "Piernas",
                type: "Máquina",
                sets: 4,
                reps: 15,
                weight: 20.0,
                icon: "figure.strengthtraining.traditional",
                color: "red"
            )
        ]
        
        addExercisesToDay(.friday, exercises: fridayExercises, viewModel: viewModel)
    }
}

// MARK: - Helper Methods

extension DefaultRoutineManager {
    
    /// Crea un ejercicio con los parámetros especificados
    private func createExercise(
        name: String,
        muscleGroup: String,
        type: String,
        sets: Int,
        reps: Int,
        weight: Double,
        icon: String = "dumbbell.fill",
        color: String = "blue"
    ) -> Exercise {
        return Exercise(
            id: UUID(),
            name: name,
            repetitions: reps,
            weight: weight,
            totalSets: sets,
            info: "Grupo muscular: \(muscleGroup)\nTipo: \(type)",
            imageData: nil,
            restDuration: 120, // 2 minutos de descanso por defecto
            sfSymbolIcon: icon,
            iconColor: color,
            segundos: 0,
            rir: 0
        )
    }
    
    /// Añade una lista de ejercicios a un día específico
    private func addExercisesToDay(
        _ day: WorkoutDay,
        exercises: [Exercise],
        viewModel: WorkoutViewModel
    ) {
        // Inicializar el array del día si no existe
        if viewModel.dailyWorkoutRecords[day] == nil {
            viewModel.dailyWorkoutRecords[day] = []
        }
        
        // Convertir cada Exercise a WorkoutExercise y añadirlo
        for exercise in exercises {
            let workoutExercise = WorkoutExercise(from: exercise)
            viewModel.dailyWorkoutRecords[day]?.append(workoutExercise)
            viewModel.exerciseRecords[workoutExercise.id] = workoutExercise
        }
        
        print("✅ Añadidos \(exercises.count) ejercicios al \(day.displayName)")
    }
}

// MARK: - Integración con WorkoutViewModel

extension WorkoutViewModel {
    
    /// Cargar rutina por defecto
    func loadDefaultRoutine() {
        DefaultRoutineManager.shared.loadDefaultRoutine(into: self)
    }
    
}
