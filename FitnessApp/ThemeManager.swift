//
//  ThemeManager.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 24/7/25.
//

import SwiftUI
import Combine

enum AccentColor: String, CaseIterable, Identifiable {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case purple = "purple"
    case red = "red"
    case pink = "pink"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .red: return .red
        case .pink: return .pink
        }
    }
}

@MainActor
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true
    @Published var selectedAccentColor: AccentColor = .blue
    @Published var isTimerEnabled: Bool = true
    
    init() {
        // Por defecto usa modo oscuro (como ya tienes configurado)
        self.isDarkMode = true
        self.selectedAccentColor = .green // Cambiado de .blue a .green
        self.isTimerEnabled = true
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
    
    func setAccentColor(_ color: AccentColor) {
        selectedAccentColor = color
    }
    
    func toggleTimer() {
        isTimerEnabled.toggle()
    }
}