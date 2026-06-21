//
//  ExerciseFormModel.swift
//  FitnessApp
//
//  Modelo para formularios de ejercicios
//
import Combine

import Foundation
import SwiftUI

enum ExerciseType: String, CaseIterable, Identifiable {
    case machine = "machine"
    case freeWeight = "freeWeight"
    case bodyWeight = "bodyWeight"
    case cardio = "cardio"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .machine: return "Máquina"
        case .freeWeight: return "Peso Libre"
        case .bodyWeight: return "Peso Corporal"
        case .cardio: return "Cardio"
        }
    }
    
    var icon: String {
        switch self {
        case .machine: return "gear"
        case .freeWeight: return "dumbbell.fill"
        case .bodyWeight: return "figure.strengthtraining.traditional"
        case .cardio: return "heart.fill"
        }
    }
}

enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case arms = "arms"
    case legs = "legs"
    case core = "core"
    case fullBody = "fullBody"
    case cardio = "cardio"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .chest: return "Pecho"
        case .back: return "Espalda"
        case .shoulders: return "Hombros"
        case .arms: return "Brazos"
        case .legs: return "Piernas"
        case .core: return "Core"
        case .fullBody: return "Cuerpo Completo"
        case .cardio: return "Cardio"
        }
    }
    
    var color: Color {
        switch self {
        case .chest: return .red
        case .back: return .green
        case .shoulders: return .orange
        case .arms: return .blue
        case .legs: return .purple
        case .core: return .yellow
        case .fullBody: return .pink
        case .cardio: return .cyan
        }
    }
    
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.weightlifting"
        case .arms: return "arm.flex"
        case .legs: return "figure.walk"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.strengthtraining.functional"
        case .cardio: return "heart.fill"
        }
    }
}

@MainActor
class ExerciseFormModel: ObservableObject {
    // Datos básicos del ejercicio
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var muscleGroup: MuscleGroup = .chest
    @Published var exerciseType: ExerciseType = .freeWeight
    
    // Días de la semana
    @Published var selectedDays: Set<WorkoutDay> = []
    
    // Parámetros del ejercicio
    @Published var hasSets: Bool = true
    @Published var sets: Int = 3
    
    @Published var hasReps: Bool = true
    @Published var reps: Int = 10
    
    @Published var hasWeight: Bool = true
    @Published var weight: Double = 0.0
    
    @Published var hasTime: Bool = false
    @Published var timeSeconds: Int = 0
    
    @Published var hasRIR: Bool = false
    @Published var rir: Int = 2
    
    @Published var restTime: Int = 120
    
    // Media
    @Published var selectedIcon: String = "dumbbell.fill"
    @Published var iconColor: Color = .blue
    @Published var imageData: Data?
    @Published var videoData: Data?
    
    // Computed property para el estado de imagen
    var hasImage: Bool {
        imageData != nil
    }
    
    // Estado del formulario
    @Published var isEditing: Bool = false
    @Published var exerciseToEdit: Exercise?
    
    init() {}
    
    init(exercise: Exercise) {
        isEditing = true
        exerciseToEdit = exercise
        loadFromExercise(exercise)
    }
    
    func loadFromExercise(_ exercise: Exercise) {
        name = exercise.name
        description = exercise.info
        
        // Inferir muscle group desde targetMuscle
        if let group = MuscleGroup.allCases.first(where: { 
            exercise.targetMuscle.lowercased().contains($0.rawValue) 
        }) {
            muscleGroup = group
        }
        
        // Inferir exercise type desde isBodyWeight
        exerciseType = exercise.isBodyWeight ? .bodyWeight : .freeWeight
        
        sets = exercise.totalSets
        reps = exercise.repetitions
        weight = exercise.weight
        timeSeconds = exercise.segundos
        rir = exercise.rir
        restTime = exercise.restDuration
        
        selectedIcon = exercise.sfSymbolIcon ?? "dumbbell.fill"
        iconColor = AppColors.accentRed
        imageData = exercise.imageData
        
        // Configurar checkboxes basados en valores
        hasSets = exercise.totalSets > 0
        hasReps = exercise.repetitions > 0
        hasWeight = exercise.weight > 0
        hasTime = exercise.segundos > 0
        hasRIR = exercise.rir > 0
    }
    
    func createExercise() -> Exercise {
        var exercise = Exercise(
            name: name,
            repetitions: hasReps ? reps : 0,
            weight: hasWeight ? weight : 0.0,
            totalSets: hasSets ? sets : 1,
            info: description,
            imageData: imageData,
            restDuration: restTime,
            sfSymbolIcon: selectedIcon,
            iconColor: iconColor.toHexString(),
            segundos: hasTime ? timeSeconds : 0,
            rir: hasRIR ? rir : 0
        )
        
        exercise.targetMuscle = muscleGroup.displayName
        exercise.isBodyWeight = exerciseType == .bodyWeight
        exercise.category = exerciseType == .cardio ? .cardio : .strength
        
        return exercise
    }
    
    func reset() {
        name = ""
        description = ""
        muscleGroup = .chest
        exerciseType = .freeWeight
        selectedDays = []
        
        hasSets = true
        sets = 3
        hasReps = true
        reps = 10
        hasWeight = true
        weight = 0.0
        hasTime = false
        timeSeconds = 0
        hasRIR = false
        rir = 2
        restTime = 120
        
        selectedIcon = "dumbbell.fill"
        iconColor = .blue
        imageData = nil
        videoData = nil
        
        isEditing = false
        exerciseToEdit = nil
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedDays.isEmpty
    }
}

extension Color {
    func toHexString() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
        return String(format: "#%06x", rgb)
    }
}
