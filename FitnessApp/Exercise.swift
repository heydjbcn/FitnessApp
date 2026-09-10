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

    init(id: UUID = UUID(), name: String, repetitions: Int, weight: Double, totalSets: Int = 4,
         info: String = "", imageData: Data? = nil, restDuration: Int = 60, sfSymbolIcon: String? = nil,
         iconColor: String = "blue", segundos: Int = 0, rir: Int = 0, muscleGroup: String? = nil) {
        self.id = id; self.name = name; self.repetitions = repetitions; self.weight = weight
        self.totalSets = totalSets; self.info = info; self.imageData = imageData
        self.restDuration = restDuration; self.sfSymbolIcon = sfSymbolIcon; self.iconColor = iconColor
        self.segundos = segundos; self.rir = rir; self.muscleGroup = muscleGroup
    }

    /// Tolerante: un campo que falte toma su valor por defecto. Si esto fallara,
    /// `loadData` dejaría la biblioteca vacía y el siguiente guardado pisaría la buena.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Ejercicio"
        repetitions = try c.decodeIfPresent(Int.self, forKey: .repetitions) ?? 10
        weight = try c.decodeIfPresent(Double.self, forKey: .weight) ?? 0
        totalSets = try c.decodeIfPresent(Int.self, forKey: .totalSets) ?? 4
        info = try c.decodeIfPresent(String.self, forKey: .info) ?? ""
        imageData = try c.decodeIfPresent(Data.self, forKey: .imageData)
        restDuration = try c.decodeIfPresent(Int.self, forKey: .restDuration) ?? 60
        sfSymbolIcon = try c.decodeIfPresent(String.self, forKey: .sfSymbolIcon)
        iconColor = try c.decodeIfPresent(String.self, forKey: .iconColor) ?? "blue"
        segundos = try c.decodeIfPresent(Int.self, forKey: .segundos) ?? 0
        rir = try c.decodeIfPresent(Int.self, forKey: .rir) ?? 0
        muscleGroup = try c.decodeIfPresent(String.self, forKey: .muscleGroup)
    }
}
