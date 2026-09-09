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

    /// Nombre completo del día ("Lunes", "Martes"…).
    var displayName: String { rawValue }

    /// Nombre corto con acentuación ("Lun", "Mié", "Sáb"…).
    var shortLabel: String {
        switch self {
        case .monday: return "Lun"
        case .tuesday: return "Mar"
        case .wednesday: return "Mié"
        case .thursday: return "Jue"
        case .friday: return "Vie"
        case .saturday: return "Sáb"
        case .sunday: return "Dom"
        }
    }

    /// Día de la semana según `Calendar` (1 = domingo … 7 = sábado).
    var calendarWeekday: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }

    /// El día de entrenamiento correspondiente a una fecha real.
    static func from(date: Date, calendar: Calendar = .current) -> WorkoutDay? {
        let weekday = calendar.component(.weekday, from: date)
        return WorkoutDay.allCases.first { $0.calendarWeekday == weekday }
    }
}
