//
//  TrainingProfile.swift
//  ChamaFit
//
//  El perfil de entreno: objetivo, nivel, días y minutos, material,
//  preferencias y limitaciones. Lo pide el onboarding y lo usan el objetivo
//  semanal, el generador de rutinas, las sugerencias y el coach.
//

import Foundation
import Combine

struct TrainingProfile: Codable, Equatable {
    enum Goal: String, Codable, CaseIterable, Identifiable {
        case strength, hypertrophy, endurance, fatLoss, health
        var id: String { rawValue }
        var label: String {
            switch self {
            case .strength: return "Ganar fuerza"
            case .hypertrophy: return "Ganar músculo"
            case .endurance: return "Resistencia"
            case .fatLoss: return "Perder grasa"
            case .health: return "Salud y forma"
            }
        }
        var icon: String {
            switch self {
            case .strength: return "scalemass.fill"
            case .hypertrophy: return "figure.strengthtraining.traditional"
            case .endurance: return "figure.run"
            case .fatLoss: return "flame.fill"
            case .health: return "heart.fill"
            }
        }
        /// Lo que entiende el generador de rutinas.
        var generatorGoal: String {
            switch self {
            case .strength: return "Fuerza"
            case .hypertrophy, .health: return "Hipertrofia"
            case .endurance: return "Resistencia"
            case .fatLoss: return "Perder grasa"
            }
        }
    }

    enum Level: String, Codable, CaseIterable, Identifiable {
        case beginner, intermediate, advanced
        var id: String { rawValue }
        var label: String {
            switch self {
            case .beginner: return "Principiante"
            case .intermediate: return "Intermedio"
            case .advanced: return "Avanzado"
            }
        }
        var detail: String {
            switch self {
            case .beginner: return "Menos de 6 meses entrenando o vuelvo tras mucho tiempo"
            case .intermediate: return "Entreno con regularidad y conozco los ejercicios básicos"
            case .advanced: return "Varios años, programo mis cargas y conozco mis marcas"
            }
        }
    }

    var goal: Goal = .hypertrophy
    var level: Level = .intermediate
    var daysPerWeek: Int = 3
    var minutes: Int = 60
    /// Perfil de material activo (Fase 2); nil = gimnasio completo.
    var equipmentProfileId: UUID? = nil
    /// Grupos musculares a priorizar.
    var focusGroups: [String] = []
    /// Ejercicios que prefiere no hacer.
    var avoidExercises: [String] = []
    /// Lesiones o molestias, en texto libre.
    var limitations: String = ""
    /// Ha pasado por el onboarding de perfil (o lo ha saltado).
    var completed: Bool = false

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        goal = (try? c.decodeIfPresent(Goal.self, forKey: .goal)) ?? .hypertrophy
        level = (try? c.decodeIfPresent(Level.self, forKey: .level)) ?? .intermediate
        daysPerWeek = try c.decodeIfPresent(Int.self, forKey: .daysPerWeek) ?? 3
        minutes = try c.decodeIfPresent(Int.self, forKey: .minutes) ?? 60
        equipmentProfileId = try c.decodeIfPresent(UUID.self, forKey: .equipmentProfileId)
        focusGroups = try c.decodeIfPresent([String].self, forKey: .focusGroups) ?? []
        avoidExercises = try c.decodeIfPresent([String].self, forKey: .avoidExercises) ?? []
        limitations = try c.decodeIfPresent(String.self, forKey: .limitations) ?? ""
        completed = try c.decodeIfPresent(Bool.self, forKey: .completed) ?? false
    }

    /// Una línea para el coach y el generador.
    var summary: String {
        var s = String(localized: "objetivo \(goal.label.lowercased()), nivel \(level.label.lowercased()), \(daysPerWeek) días × \(minutes) min")
        if !focusGroups.isEmpty { s += String(localized: "; priorizar \(focusGroups.joined(separator: ", ").lowercased())") }
        if !avoidExercises.isEmpty { s += String(localized: "; evitar \(avoidExercises.joined(separator: ", "))") }
        let lim = limitations.trimmingCharacters(in: .whitespacesAndNewlines)
        if !lim.isEmpty { s += String(localized: "; limitaciones: \(lim)") }
        return s
    }
}

extension WorkoutViewModel {

    var trainingProfile: TrainingProfile {
        get {
            guard let data = userDefaults.data(forKey: "TrainingProfile"),
                  let p = try? JSONDecoder().decode(TrainingProfile.self, from: data) else { return TrainingProfile() }
            return p
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) { userDefaults.set(data, forKey: "TrainingProfile") }
            // El objetivo de sesiones de la semana sale del perfil.
            weeklySessionGoal = newValue.daysPerWeek
            objectWillChange.send()
        }
    }

    /// El formulario del generador de rutinas, rellenado con el perfil.
    func routineRequestFromProfile() -> RoutineRequest {
        let p = trainingProfile
        var r = RoutineRequest()
        r.goal = p.goal.generatorGoal
        r.daysPerWeek = min(6, max(2, p.daysPerWeek))
        r.minutes = [30, 45, 60, 75].min { abs($0 - p.minutes) < abs($1 - p.minutes) } ?? 60
        r.level = p.level.label
        r.equipment = equipmentLabelForGenerator
        r.extra = p.summary
        return r
    }
}
