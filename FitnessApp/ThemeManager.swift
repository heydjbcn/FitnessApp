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
    @Published var isDarkMode: Bool = true {
        didSet {
            saveThemeSettings()
        }
    }
    
    @Published var selectedAccentColor: AccentColor = .blue {
        didSet {
            saveThemeSettings()
        }
    }
    
    @Published var isTimerEnabled: Bool = true {
        didSet {
            saveThemeSettings()
        }
    }
    
    private var isLoading = false // Prevenir bucles durante carga
    
    init() {
        loadThemeSettings()
    }
    
    private func loadThemeSettings() {
        isLoading = true
        
        // Cargar configuraciones de UserDefaults
        self.isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
        
        if let accentColorRaw = UserDefaults.standard.string(forKey: "selectedAccentColor"),
           let accentColor = AccentColor(rawValue: accentColorRaw) {
            self.selectedAccentColor = accentColor
        } else {
            self.selectedAccentColor = .green
        }
        
        self.isTimerEnabled = UserDefaults.standard.object(forKey: "isTimerEnabled") as? Bool ?? true
        
        isLoading = false
        print("ThemeManager: Configuración cargada - DarkMode: \(isDarkMode), AccentColor: \(selectedAccentColor.rawValue), Timer: \(isTimerEnabled)")
    }
    
    private func saveThemeSettings() {
        guard !isLoading else { return } // No guardar durante la carga inicial
        
        // Capturar valores en el hilo principal antes de pasar al background
        let currentDarkMode = isDarkMode
        let currentAccentColor = selectedAccentColor.rawValue
        let currentTimerEnabled = isTimerEnabled
        
        DispatchQueue.global(qos: .background).async {
            UserDefaults.standard.set(currentDarkMode, forKey: "isDarkMode")
            UserDefaults.standard.set(currentAccentColor, forKey: "selectedAccentColor")
            UserDefaults.standard.set(currentTimerEnabled, forKey: "isTimerEnabled")
            
            DispatchQueue.main.async {
                print("ThemeManager: Configuración guardada - DarkMode: \(currentDarkMode)")
            }
        }
    }
    
    func toggleTheme() {
        print("ThemeManager: Cambiando tema de \(isDarkMode ? "oscuro" : "claro") a \(isDarkMode ? "claro" : "oscuro")")
        
        // Usar animación suave para el cambio
        withAnimation(.easeInOut(duration: 0.3)) {
            isDarkMode.toggle()
        }
    }
    
    func setAccentColor(_ color: AccentColor) {
        print("ThemeManager: Cambiando color de acento a \(color.rawValue)")
        selectedAccentColor = color
    }
    
    func toggleTimer() {
        print("ThemeManager: Cambiando estado del timer a \(isTimerEnabled ? "desactivado" : "activado")")
        isTimerEnabled.toggle()
    }
}