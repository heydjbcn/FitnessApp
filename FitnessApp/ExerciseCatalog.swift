//
//  ExerciseCatalog.swift
//  FitnessApp
//
//  Catálogo local de ejercicios comunes para elegir al crear (sin backend).
//

import Foundation

struct CatalogExercise: Identifiable {
    let id = UUID()
    let name: String
    let muscleGroup: String
    let icon: String        // SF Symbol
    var reps: Int = 10
    var weight: Double = 0
    var sets: Int = 4
}

enum ExerciseCatalog {
    static let all: [CatalogExercise] = [
        // Pecho
        CatalogExercise(name: "Press de banca", muscleGroup: "Pecho", icon: "dumbbell.fill", reps: 8, weight: 40),
        CatalogExercise(name: "Press inclinado mancuernas", muscleGroup: "Pecho", icon: "dumbbell.fill", reps: 10, weight: 20),
        CatalogExercise(name: "Aperturas", muscleGroup: "Pecho", icon: "figure.strengthtraining.traditional", reps: 12, weight: 12),
        CatalogExercise(name: "Fondos", muscleGroup: "Pecho", icon: "figure.strengthtraining.functional", reps: 10),
        CatalogExercise(name: "Flexiones", muscleGroup: "Pecho", icon: "figure.core.training", reps: 15),
        // Espalda
        CatalogExercise(name: "Dominadas", muscleGroup: "Espalda", icon: "figure.strengthtraining.functional", reps: 8),
        CatalogExercise(name: "Remo con barra", muscleGroup: "Espalda", icon: "dumbbell.fill", reps: 10, weight: 40),
        CatalogExercise(name: "Jalón al pecho", muscleGroup: "Espalda", icon: "figure.strengthtraining.traditional", reps: 12, weight: 45),
        CatalogExercise(name: "Remo en máquina", muscleGroup: "Espalda", icon: "figure.strengthtraining.traditional", reps: 12, weight: 40),
        CatalogExercise(name: "Peso muerto", muscleGroup: "Espalda", icon: "dumbbell.fill", reps: 6, weight: 60),
        // Hombros
        CatalogExercise(name: "Press militar", muscleGroup: "Hombros", icon: "dumbbell.fill", reps: 10, weight: 25),
        CatalogExercise(name: "Elevaciones laterales", muscleGroup: "Hombros", icon: "figure.strengthtraining.traditional", reps: 15, weight: 8),
        CatalogExercise(name: "Elevaciones frontales", muscleGroup: "Hombros", icon: "figure.strengthtraining.traditional", reps: 12, weight: 8),
        CatalogExercise(name: "Pájaros", muscleGroup: "Hombros", icon: "figure.strengthtraining.traditional", reps: 15, weight: 6),
        // Bíceps
        CatalogExercise(name: "Curl con barra", muscleGroup: "Bíceps", icon: "dumbbell.fill", reps: 10, weight: 20),
        CatalogExercise(name: "Curl con mancuernas", muscleGroup: "Bíceps", icon: "dumbbell.fill", reps: 12, weight: 12),
        CatalogExercise(name: "Curl martillo", muscleGroup: "Bíceps", icon: "dumbbell.fill", reps: 12, weight: 12),
        // Tríceps
        CatalogExercise(name: "Press francés", muscleGroup: "Tríceps", icon: "dumbbell.fill", reps: 10, weight: 20),
        CatalogExercise(name: "Extensiones en polea", muscleGroup: "Tríceps", icon: "figure.strengthtraining.traditional", reps: 14, weight: 25),
        CatalogExercise(name: "Fondos en banco", muscleGroup: "Tríceps", icon: "figure.strengthtraining.functional", reps: 12),
        // Piernas
        CatalogExercise(name: "Sentadilla", muscleGroup: "Piernas", icon: "figure.strengthtraining.functional", reps: 8, weight: 60),
        CatalogExercise(name: "Prensa", muscleGroup: "Piernas", icon: "figure.strengthtraining.traditional", reps: 12, weight: 120),
        CatalogExercise(name: "Extensión de cuádriceps", muscleGroup: "Piernas", icon: "figure.strengthtraining.traditional", reps: 15, weight: 40),
        CatalogExercise(name: "Curl femoral", muscleGroup: "Piernas", icon: "figure.strengthtraining.traditional", reps: 12, weight: 35),
        CatalogExercise(name: "Zancadas", muscleGroup: "Piernas", icon: "figure.walk", reps: 12, weight: 16),
        CatalogExercise(name: "Gemelos de pie", muscleGroup: "Piernas", icon: "figure.strengthtraining.functional", reps: 18, weight: 40),
        // Glúteos
        CatalogExercise(name: "Hip thrust", muscleGroup: "Glúteos", icon: "figure.strengthtraining.traditional", reps: 10, weight: 60),
        CatalogExercise(name: "Patada de glúteo", muscleGroup: "Glúteos", icon: "figure.strengthtraining.traditional", reps: 15, weight: 15),
        CatalogExercise(name: "Abducción de cadera", muscleGroup: "Glúteos", icon: "figure.strengthtraining.traditional", reps: 20, weight: 20),
        CatalogExercise(name: "Puente de glúteo", muscleGroup: "Glúteos", icon: "figure.core.training", reps: 15),
        // Core
        CatalogExercise(name: "Plancha", muscleGroup: "Core", icon: "figure.core.training", reps: 0, sets: 3),
        CatalogExercise(name: "Crunch", muscleGroup: "Core", icon: "figure.core.training", reps: 20),
        CatalogExercise(name: "Elevación de piernas", muscleGroup: "Core", icon: "figure.core.training", reps: 15),
        CatalogExercise(name: "Russian twist", muscleGroup: "Core", icon: "figure.core.training", reps: 20, weight: 8),
        // Cardio
        CatalogExercise(name: "Cinta de correr", muscleGroup: "Cardio", icon: "figure.run", reps: 0, sets: 1),
        CatalogExercise(name: "Bicicleta estática", muscleGroup: "Cardio", icon: "figure.indoor.cycle", reps: 0, sets: 1),
        CatalogExercise(name: "Elíptica", muscleGroup: "Cardio", icon: "figure.elliptical", reps: 0, sets: 1),
        CatalogExercise(name: "Remo", muscleGroup: "Cardio", icon: "figure.rower", reps: 0, sets: 1)
    ]

    static func filtered(group: String?, query: String) -> [CatalogExercise] {
        all.filter { ex in
            (group == nil || ex.muscleGroup == group) &&
            (query.isEmpty || ex.name.localizedCaseInsensitiveContains(query))
        }
    }
}
