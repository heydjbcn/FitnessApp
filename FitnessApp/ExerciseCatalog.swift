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
    /// Por tiempo (reps = 0): segundos de partida.
    var seconds: Int = 0

    /// Material, tipo de carga, errores, variantes y alternativas.
    var details: ExerciseLibrary.Details? { ExerciseLibrary.details(for: name) }
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
        CatalogExercise(name: "Plancha", muscleGroup: "Core", icon: "figure.core.training", reps: 0, sets: 3, seconds: 45),
        CatalogExercise(name: "Crunch", muscleGroup: "Core", icon: "figure.core.training", reps: 20),
        CatalogExercise(name: "Elevación de piernas", muscleGroup: "Core", icon: "figure.core.training", reps: 15),
        CatalogExercise(name: "Russian twist", muscleGroup: "Core", icon: "figure.core.training", reps: 20, weight: 8),
        // Cardio
        CatalogExercise(name: "Cinta de correr", muscleGroup: "Cardio", icon: "figure.run", reps: 0, sets: 1, seconds: 900),
        CatalogExercise(name: "Bicicleta estática", muscleGroup: "Cardio", icon: "figure.indoor.cycle", reps: 0, sets: 1, seconds: 900),
        CatalogExercise(name: "Elíptica", muscleGroup: "Cardio", icon: "figure.elliptical", reps: 0, sets: 1, seconds: 900),
        CatalogExercise(name: "Remo", muscleGroup: "Cardio", icon: "figure.rower", reps: 0, sets: 1, seconds: 600),
        // Pecho (casa, mancuernas, máquinas)
        CatalogExercise(name: "Press de banca con mancuernas", muscleGroup: "Pecho", icon: "dumbbell.fill", reps: 10, weight: 20),
        CatalogExercise(name: "Cruce de poleas", muscleGroup: "Pecho", icon: "figure.strengthtraining.traditional", reps: 12, weight: 10),
        CatalogExercise(name: "Press de pecho en máquina", muscleGroup: "Pecho", icon: "figure.strengthtraining.traditional", reps: 10, weight: 40),
        CatalogExercise(name: "Flexiones inclinadas", muscleGroup: "Pecho", icon: "figure.core.training", reps: 12),
        CatalogExercise(name: "Flexiones declinadas", muscleGroup: "Pecho", icon: "figure.core.training", reps: 10),
        // Espalda
        CatalogExercise(name: "Remo con mancuerna", muscleGroup: "Espalda", icon: "dumbbell.fill", reps: 10, weight: 20),
        CatalogExercise(name: "Dominadas asistidas", muscleGroup: "Espalda", icon: "figure.strengthtraining.functional", reps: 8, weight: 30),
        CatalogExercise(name: "Remo invertido", muscleGroup: "Espalda", icon: "figure.strengthtraining.functional", reps: 10),
        CatalogExercise(name: "Pullover en polea", muscleGroup: "Espalda", icon: "figure.strengthtraining.traditional", reps: 12, weight: 20),
        CatalogExercise(name: "Hiperextensiones", muscleGroup: "Espalda", icon: "figure.core.training", reps: 12),
        // Hombros
        CatalogExercise(name: "Press de hombros con mancuernas", muscleGroup: "Hombros", icon: "dumbbell.fill", reps: 10, weight: 14),
        CatalogExercise(name: "Face pull", muscleGroup: "Hombros", icon: "figure.strengthtraining.traditional", reps: 15, weight: 15),
        CatalogExercise(name: "Press Arnold", muscleGroup: "Hombros", icon: "dumbbell.fill", reps: 10, weight: 12),
        CatalogExercise(name: "Flexiones en pica", muscleGroup: "Hombros", icon: "figure.core.training", reps: 8),
        // Bíceps
        CatalogExercise(name: "Curl en polea", muscleGroup: "Bíceps", icon: "figure.strengthtraining.traditional", reps: 12, weight: 15),
        CatalogExercise(name: "Curl con banda", muscleGroup: "Bíceps", icon: "figure.strengthtraining.functional", reps: 15),
        CatalogExercise(name: "Curl concentrado", muscleGroup: "Bíceps", icon: "dumbbell.fill", reps: 12, weight: 10),
        // Tríceps
        CatalogExercise(name: "Extensión de tríceps sobre la cabeza", muscleGroup: "Tríceps", icon: "dumbbell.fill", reps: 12, weight: 14),
        CatalogExercise(name: "Patada de tríceps", muscleGroup: "Tríceps", icon: "dumbbell.fill", reps: 12, weight: 6),
        CatalogExercise(name: "Flexiones diamante", muscleGroup: "Tríceps", icon: "figure.core.training", reps: 10),
        CatalogExercise(name: "Press de banca agarre cerrado", muscleGroup: "Tríceps", icon: "dumbbell.fill", reps: 8, weight: 35),
        // Piernas
        CatalogExercise(name: "Sentadilla goblet", muscleGroup: "Piernas", icon: "figure.strengthtraining.functional", reps: 10, weight: 16),
        CatalogExercise(name: "Sentadilla búlgara", muscleGroup: "Piernas", icon: "figure.strengthtraining.functional", reps: 10, weight: 10),
        CatalogExercise(name: "Peso muerto rumano", muscleGroup: "Piernas", icon: "dumbbell.fill", reps: 10, weight: 40),
        CatalogExercise(name: "Sentadilla sin peso", muscleGroup: "Piernas", icon: "figure.strengthtraining.functional", reps: 20),
        CatalogExercise(name: "Subida al banco", muscleGroup: "Piernas", icon: "figure.stair.stepper", reps: 10, weight: 8),
        CatalogExercise(name: "Gemelos sentado", muscleGroup: "Piernas", icon: "figure.strengthtraining.traditional", reps: 15, weight: 30),
        // Glúteos
        CatalogExercise(name: "Swing con kettlebell", muscleGroup: "Glúteos", icon: "figure.strengthtraining.functional", reps: 15, weight: 16),
        CatalogExercise(name: "Puente de glúteo a una pierna", muscleGroup: "Glúteos", icon: "figure.core.training", reps: 12),
        CatalogExercise(name: "Paso lateral con banda", muscleGroup: "Glúteos", icon: "figure.walk", reps: 15, sets: 3),
        // Core
        CatalogExercise(name: "Plancha lateral", muscleGroup: "Core", icon: "figure.core.training", reps: 0, sets: 3, seconds: 30),
        CatalogExercise(name: "Dead bug", muscleGroup: "Core", icon: "figure.core.training", reps: 12, sets: 3),
        CatalogExercise(name: "Rueda abdominal", muscleGroup: "Core", icon: "figure.core.training", reps: 10, sets: 3),
        CatalogExercise(name: "Pallof press", muscleGroup: "Core", icon: "figure.strengthtraining.traditional", reps: 12, weight: 10, sets: 3),
        CatalogExercise(name: "Escaladores", muscleGroup: "Core", icon: "figure.core.training", reps: 0, sets: 3, seconds: 30),
        CatalogExercise(name: "Bird dog", muscleGroup: "Core", icon: "figure.core.training", reps: 10, sets: 3),
        // Cardio
        CatalogExercise(name: "Burpees", muscleGroup: "Cardio", icon: "figure.highintensity.intervaltraining", reps: 10, sets: 3),
        CatalogExercise(name: "Comba", muscleGroup: "Cardio", icon: "figure.jumprope", reps: 0, sets: 3, seconds: 60),
        CatalogExercise(name: "Jumping jacks", muscleGroup: "Cardio", icon: "figure.mixed.cardio", reps: 0, sets: 3, seconds: 40),
        // Movilidad
        CatalogExercise(name: "Gato-camello", muscleGroup: "Movilidad", icon: "figure.flexibility", reps: 10, sets: 1),
        CatalogExercise(name: "Movilidad de cadera 90/90", muscleGroup: "Movilidad", icon: "figure.flexibility", reps: 0, sets: 2, seconds: 45),
        CatalogExercise(name: "Rotaciones torácicas", muscleGroup: "Movilidad", icon: "figure.flexibility", reps: 10, sets: 2),
        CatalogExercise(name: "Dislocaciones de hombro con banda", muscleGroup: "Movilidad", icon: "figure.flexibility", reps: 12, sets: 2),
        CatalogExercise(name: "Estiramiento de isquiotibiales", muscleGroup: "Movilidad", icon: "figure.flexibility", reps: 0, sets: 2, seconds: 40),
        CatalogExercise(name: "Movilidad de tobillo", muscleGroup: "Movilidad", icon: "figure.flexibility", reps: 10, sets: 2),
    ]


    /// Por nombre, sin mirar mayúsculas ni tildes, en español o en el idioma de la app.
    static func entry(named name: String) -> CatalogExercise? {
        let key = ExerciseLibrary.fold(name)
        return all.first { ExerciseLibrary.fold($0.name) == key }
            ?? (AppLanguage.isSpanish ? nil : all.first { ExerciseLibrary.fold($0.name.loc) == key })
    }

    /// El nombre del catálogo (en español, que es la clave de técnica, vídeo y
    /// alternativas) para un ejercicio que puede llamarse «Bench press».
    static func canonicalName(_ name: String) -> String { entry(named: name)?.name ?? name }

    static func filtered(group: String?, query: String) -> [CatalogExercise] {
        all.filter { ex in
            (group == nil || ex.muscleGroup == group) &&
            (query.isEmpty || ex.name.localizedCaseInsensitiveContains(query))
        }
    }
}
