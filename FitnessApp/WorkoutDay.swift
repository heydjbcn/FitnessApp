//
//  WorkoutDay.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import Foundation

enum WorkoutDay: String, CaseIterable, Identifiable, Codable, Hashable {
    case monday    = "Lunes"
    case tuesday   = "Martes"
    case wednesday = "Miércoles"
    case thursday  = "Jueves"
    case friday    = "Viernes"

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
        }
    }
    
    var shortDisplayName: String {
        return shortName
    }
    
    var iconName: String {
        switch self {
        case .monday: return "calendar.badge.clock"
        case .tuesday: return "calendar.badge.plus"
        case .wednesday: return "calendar.badge.checkmark"
        case .thursday: return "calendar.badge.exclamationmark"
        case .friday: return "calendar.badge.minus"
        }
    }
    
    // Get the weekday number (1 = Sunday, 2 = Monday, etc.)
    var weekdayNumber: Int {
        switch self {
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        }
    }
    
    // Create WorkoutDay from Date
    static func from(date: Date) -> WorkoutDay? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        switch weekday {
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return nil // Weekend days not supported
        }
    }
    
    // Get next workout day
    var nextDay: WorkoutDay? {
        let allCases = WorkoutDay.allCases
        guard let currentIndex = allCases.firstIndex(of: self) else { return nil }
        let nextIndex = currentIndex + 1
        return nextIndex < allCases.count ? allCases[nextIndex] : allCases.first
    }
    
    // Get previous workout day
    var previousDay: WorkoutDay? {
        let allCases = WorkoutDay.allCases
        guard let currentIndex = allCases.firstIndex(of: self) else { return nil }
        let previousIndex = currentIndex - 1
        return previousIndex >= 0 ? allCases[previousIndex] : allCases.last
    }
}
