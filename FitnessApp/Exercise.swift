//
//  Exercise.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import Foundation
import SwiftUI

struct Exercise: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var repetitions: Int
    var weight: Double
    var totalSets: Int = 4
    var completedSets: Int = 0
    var lastSetCompletedAt: Date?
    var info: String = ""
    var imageData: Data? = nil
    var restDuration: Int = 60 // Tiempo de descanso en segundos, por defecto 1 minuto

    var isCompleted: Bool {
        completedSets >= totalSets
    }
}
