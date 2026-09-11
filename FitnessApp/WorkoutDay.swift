//
//  WorkoutDay.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import Foundation

extension Int {
    /// Convierte el día de `Calendar` (1 = domingo) al orden que usa la app,
    /// donde la semana empieza en lunes.
    var mondayFirst: Int { self == 1 ? 7 : self - 1 }
}

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
        if !AppLanguage.isSpanish { return shortLabel.uppercased(with: AppLanguage.locale) }
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

    /// Nombre completo del día en el idioma de la app ("Lunes", "Monday", "Dilluns").
    var displayName: String {
        guard !AppLanguage.isSpanish else { return rawValue }
        let f = DateFormatter(); f.locale = AppLanguage.locale
        return f.standaloneWeekdaySymbols[calendarWeekday - 1].capitalized(with: AppLanguage.locale)
    }

    /// Nombre corto con acentuación ("Lun", "Mié", "Sáb"…).
    var shortLabel: String {
        if !AppLanguage.isSpanish {
            let f = DateFormatter(); f.locale = AppLanguage.locale
            return f.shortStandaloneWeekdaySymbols[calendarWeekday - 1].replacingOccurrences(of: ".", with: "").capitalized(with: AppLanguage.locale)
        }
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

    /// Orden natural de la semana empezando en lunes (1 = lunes … 7 = domingo).
    var weekOrder: Int { calendarWeekday.mondayFirst }

    /// El día de entrenamiento correspondiente a una fecha real.
    static func from(date: Date, calendar: Calendar = .current) -> WorkoutDay? {
        let weekday = calendar.component(.weekday, from: date)
        return WorkoutDay.allCases.first { $0.calendarWeekday == weekday }
    }
}
