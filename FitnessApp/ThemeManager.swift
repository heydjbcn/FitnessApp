import SwiftUI
import Combine

// Definir colores de acento disponibles
enum AccentColor: String, CaseIterable, Identifiable {
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case orange = "orange"
    case red = "red"
    case pink = "pink"
    case teal = "teal"
    case indigo = "indigo"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }
    
    var displayName: String {
        switch self {
        case .green: return "Verde"
        case .blue: return "Azul"
        case .purple: return "Morado"
        case .orange: return "Naranja"
        case .red: return "Rojo"
        case .pink: return "Rosa"
        case .teal: return "Azul Verdoso"
        case .indigo: return "Índigo"
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            // Haptic feedback para cambio de tema
            HapticManager.shared.themeChanged()
        }
    }
    
    @Published var isTimerEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isTimerEnabled, forKey: "isTimerEnabled")
            // Haptic feedback para toggle de configuración
            HapticManager.shared.settingToggled()
        }
    }
    
    @Published var selectedAccentColor: AccentColor = .green {
        didSet {
            UserDefaults.standard.set(selectedAccentColor.rawValue, forKey: "selectedAccentColor")
            // Haptic feedback para cambio de color de acento
            HapticManager.shared.selectionFeedback()
        }
    }
    
    init() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        isTimerEnabled = UserDefaults.standard.object(forKey: "isTimerEnabled") as? Bool ?? true
        
        if let colorString = UserDefaults.standard.string(forKey: "selectedAccentColor"),
           let accentColor = AccentColor(rawValue: colorString) {
            selectedAccentColor = accentColor
        }
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
    
    func toggleTimer() {
        isTimerEnabled.toggle()
    }
    
    func setAccentColor(_ color: AccentColor) {
        selectedAccentColor = color
    }
}
