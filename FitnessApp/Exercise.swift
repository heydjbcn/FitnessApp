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
    var info: String = ""
    var imageData: Data? = nil
    var restDuration: Int = 60 // Tiempo de descanso en segundos, por defecto 1 minuto
    var sfSymbolIcon: String? = nil // Icono de SF Symbols como alternativa a la imagen
    var iconColor: String = "blue" // Color del icono SF Symbol
    var segundos: Int = 0 // Campo para segundos
    var rir: Int = 0 // Campo para RIR (Reps in Reserve)
    var muscleGroup: String? = nil // Grupo muscular (opcional, compatible con datos antiguos)
}
