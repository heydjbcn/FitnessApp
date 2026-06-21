//
//  SetLog.swift
//  FitnessApp
//
//  Registro real de una serie ejecutada (peso y repeticiones reales),
//  base del seguimiento por sesión estilo Strong/Hevy.
//

import Foundation

enum SetType: String, Codable, CaseIterable {
    case normal
    case warmup
    case drop
    case failure

    var label: String {
        switch self {
        case .normal:  return "Normal"
        case .warmup:  return "Calentamiento"
        case .drop:    return "Drop set"
        case .failure: return "Al fallo"
        }
    }

    /// Etiqueta corta para mostrar en la serie.
    var shortTag: String? {
        switch self {
        case .normal:  return nil
        case .warmup:  return "W"
        case .drop:    return "D"
        case .failure: return "F"
        }
    }
}

struct SetLog: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var reps: Int
    var weight: Double
    var type: SetType = .normal
    var rpe: Int? = nil
    var date: Date = Date()

    init(id: UUID = UUID(), reps: Int, weight: Double, type: SetType = .normal, rpe: Int? = nil, date: Date = Date()) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.type = type
        self.rpe = rpe
        self.date = date
    }

    enum CodingKeys: String, CodingKey { case id, reps, weight, type, rpe, date }

    // Decode tolerante para compatibilidad futura.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        reps = try c.decodeIfPresent(Int.self, forKey: .reps) ?? 0
        weight = try c.decodeIfPresent(Double.self, forKey: .weight) ?? 0
        type = try c.decodeIfPresent(SetType.self, forKey: .type) ?? .normal
        rpe = try c.decodeIfPresent(Int.self, forKey: .rpe)
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
    }

    /// 1RM estimado (Epley) de esta serie.
    var estimatedOneRepMax: Double {
        guard reps > 0, weight > 0 else { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }

    /// Volumen de la serie (peso × reps).
    var volume: Double { weight * Double(reps) }
}
