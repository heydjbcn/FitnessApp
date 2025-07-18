import SwiftUI
import Combine

// Enum para el tema
enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
}

struct AppColors {
    static let primary = Color(red: 0/255, green: 255/255, blue: 102/255) // Verde brillante (siempre igual)
    
    // Colores dinámicos que cambian según el tema
    static func background(isDark: Bool) -> Color {
        isDark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white
    }
    
    static func cardBackground(isDark: Bool) -> Color {
        isDark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    static func textPrimary(isDark: Bool) -> Color {
        isDark ? Color.white : Color.black
    }
    
    static func textSecondary(isDark: Bool) -> Color {
        isDark ? Color(red: 0.8, green: 0.8, blue: 0.8) : Color(red: 0.6, green: 0.6, blue: 0.6)
    }
    
    // Funciones de compatibilidad con el enum (mantener si se usan en otras partes)
    static func background(for theme: AppTheme) -> Color {
        switch theme {
        case .light: return Color.white
        case .dark: return Color(red: 28/255, green: 28/255, blue: 30/255) // Gris muy oscuro
        }
    }
    
    static func cardBackground(for theme: AppTheme) -> Color {
        switch theme {
        case .light: return Color(red: 247/255, green: 247/255, blue: 247/255) // #F7F7F7
        case .dark: return Color(red: 44/255, green: 44/255, blue: 46/255) // Gris oscuro para tarjetas
        }
    }
    
    static func textPrimary(for theme: AppTheme) -> Color {
        switch theme {
        case .light: return Color.black
        case .dark: return Color.white
        }
    }
    
    static func textSecondary(for theme: AppTheme) -> Color {
        switch theme {
        case .light: return Color(white: 0.4)
        case .dark: return Color(white: 0.7)
        }
    }
    
    // Colores estáticos que no cambian
    static let secondaryGray = Color(red: 230/255, green: 230/255, blue: 230/255)
    static let accentCyan = Color(red: 0.0, green: 0.85, blue: 0.85)
    static let danger = Color.red
    static let success = Color.green
    
    // Para compatibilidad con código existente (modo claro por defecto)
    static let background = Color.white
    static let cardBackground = Color(red: 247/255, green: 247/255, blue: 247/255)
    static let textPrimary = Color.black
    static let textSecondary = Color(white: 0.4)
}

struct AppFonts {
    static let title = Font.system(size: 22, weight: .bold)
    static let subtitle = Font.system(size: 16, weight: .semibold)
    static let body = Font.system(size: 15)
    static let caption = Font.system(size: 13)
}