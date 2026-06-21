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
        case .green:  return AppColors.accentLime
        case .blue:   return AppColors.accentBlue
        case .purple: return AppColors.accentPurple
        case .orange: return AppColors.accentOrange
        case .red:    return AppColors.accentRed
        case .pink:   return AppColors.accentPink
        case .teal:   return AppColors.accentTeal
        case .indigo: return AppColors.accentIndigo
        }
    }

    /// Color de texto/icono legible ENCIMA del acento (contraste).
    var onColor: Color {
        switch self {
        case .green: return Color(hex: "#0B0D0F") // lima es muy claro → texto oscuro
        default:     return .white
        }
    }

    var displayName: String {
        switch self {
        case .green: return "Lima eléctrico"
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
    
    @Published var selectedAccentColor: AccentColor = .green {
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
