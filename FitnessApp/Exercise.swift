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
    /// Ajustes de la máquina que no cambian: "asiento 4, agarre ancho".
    var setupNote: String? = nil
    /// Récord que se quiere alcanzar (kg).
    var goalWeight: Double? = nil
    /// Qué significa el peso: total, por mancuerna, por lado, asistencia o lastre.
    var loadKind: LoadKind = .total
    /// Enlace a un vídeo propio (YouTube, Instagram…). Si no, el del catálogo.
    var videoURL: String? = nil

    init(id: UUID = UUID(), name: String, repetitions: Int, weight: Double, totalSets: Int = 4,
         info: String = "", imageData: Data? = nil, restDuration: Int = 60, sfSymbolIcon: String? = nil,
         iconColor: String = "blue", segundos: Int = 0, rir: Int = 0, muscleGroup: String? = nil,
         setupNote: String? = nil, goalWeight: Double? = nil, loadKind: LoadKind = .total) {
        self.id = id; self.name = name; self.repetitions = repetitions; self.weight = weight
        self.totalSets = totalSets; self.info = info; self.imageData = imageData
        self.restDuration = restDuration; self.sfSymbolIcon = sfSymbolIcon; self.iconColor = iconColor
        self.segundos = segundos; self.rir = rir; self.muscleGroup = muscleGroup
        self.setupNote = setupNote; self.goalWeight = goalWeight; self.loadKind = loadKind
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
        setupNote = try c.decodeIfPresent(String.self, forKey: .setupNote)
        goalWeight = try c.decodeIfPresent(Double.self, forKey: .goalWeight)
        loadKind = (try? c.decodeIfPresent(LoadKind.self, forKey: .loadKind)) ?? .total
        videoURL = try? c.decodeIfPresent(String.self, forKey: .videoURL)
    }

    /// La nota de máquina, si tiene algo escrito.
    var setupText: String? {
        guard let t = setupNote?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        return t
    }
}

/// Qué representa el peso apuntado en un ejercicio.
enum LoadKind: String, Codable, CaseIterable, Identifiable {
    /// El peso total que mueves (barra con discos, máquina).
    case total
    /// Lo que pesa cada mancuerna (se usan dos).
    case perDumbbell
    /// Por brazo o pierna, haciendo cada lado (zancadas con una mancuerna, remo a una mano).
    case perSide
    /// Máquina de asistencia: el peso te ayuda, así que menos es mejor.
    case assisted
    /// Tu peso corporal más un lastre (0 = sin lastre).
    case bodyweight

    var id: String { rawValue }

    var label: String {
        switch self {
        case .total: return "Peso total"
        case .perDumbbell: return "Por mancuerna"
        case .perSide: return "Por lado"
        case .assisted: return "Asistido"
        case .bodyweight: return "Corporal + lastre"
        }
    }

    var help: String {
        switch self {
        case .total: return "Apuntas lo que mueves en total: barra con discos o la placa de la máquina."
        case .perDumbbell: return "Apuntas lo que pesa una mancuerna. En el tonelaje cuenta el doble."
        case .perSide: return "Apuntas el peso de un lado y haces los dos. En el tonelaje cuenta el doble."
        case .assisted: return "Apuntas la ayuda de la máquina. Progresar es bajarla: el récord es la menor."
        case .bodyweight: return "Apuntas el lastre (0 sin lastre). El tonelaje suma tu peso corporal."
        }
    }

    /// Cómo se llama el campo de peso para este tipo.
    var fieldLabel: String {
        switch self {
        case .total: return "Peso"
        case .perDumbbell: return "Por mancuerna"
        case .perSide: return "Por lado"
        case .assisted: return "Asistencia"
        case .bodyweight: return "Lastre"
        }
    }

    /// Menos peso es mejor (asistencia).
    var lowerIsBetter: Bool { self == .assisted }
}

