//
//  WorkoutExercise.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 18/7/25.
//

import Foundation

struct WorkoutExercise: Identifiable, Codable, Equatable {
    var id = UUID() // Este ID es ÚNICO para esta ocurrencia del ejercicio en un día específico
    var exerciseId: UUID // ID del Exercise base al que se refiere
    var completedSets: Int = 0
    var lastSetCompletedAt: Date?
    
    // isCompleted se calculará en el ViewModel usando el Exercise base
}
