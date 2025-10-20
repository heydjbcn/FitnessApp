//
//  WorkoutDay.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import Foundation

enum WorkoutDay: String, CaseIterable, Identifiable, Codable {
    case monday    = "Lunes"
    case tuesday   = "Martes"
    case wednesday = "Miércoles"
    case thursday  = "Jueves"
    case friday    = "Viernes"
    case saturday  = "Sábado"
    case sunday    = "Domingo"

    var id: String { self.rawValue }

    var displayName: String {
        return self.rawValue
    }

    var shortName: String {
        switch self {
        case .monday: return "LUN"
        case .tuesday: return "MAR"
        case .wednesday: return "MIE"
        case .thursday: return "JUE"
        case .friday: return "VIE"
        case .saturday: return "SAB"
        case .sunday: return "DOM"
        }
    }
}
