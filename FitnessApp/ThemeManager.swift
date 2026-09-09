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
    
    /// Color plano del acento en tema oscuro. Para resolverlo según el tema
    /// vivo, usa `accent(isDark:)` de PulsoTokens.
    var color: Color { accent(isDark: true) }

    /// Color de texto/icono legible ENCIMA del acento (contraste).
    var onColor: Color { onAccent(isDark: true) }

    /// Nombre del degradado, como lo llama el diseño.
    var displayName: String {
        switch self {
        case .purple: return "Violeta"
        case .red:    return "Coral"
        case .green:  return "Lima"
        case .pink:   return "Rosa"
        case .orange: return "Ámbar"
        case .blue:   return "Azul"
        case .teal:   return "Turquesa"
        case .indigo: return "Índigo"
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true {
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
    
    // Violeta es el acento por defecto del rediseño «Pulso». Solo afecta a
    // instalaciones nuevas: si hay preferencia guardada, manda esa.
    @Published var selectedAccentColor: AccentColor = .purple {
        didSet {
            UserDefaults.standard.set(selectedAccentColor.rawValue, forKey: "selectedAccentColor")
            // Haptic feedback para cambio de color de acento
            HapticManager.shared.selectionFeedback()
        }
    }
    
    init() {
        isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
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
