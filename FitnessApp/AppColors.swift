//
//  AppColors.swift
//  FitnessApp
//
//  Sistema de colores moderno inspirado en el diseño
//

import SwiftUI

struct AppColors {
    // MARK: - Colores principales del tema oscuro moderno
    
    static let backgroundPrimary = Color(red: 0.08, green: 0.08, blue: 0.08) // #141414
    static let backgroundSecondary = Color(red: 0.12, green: 0.12, blue: 0.12) // #1E1E1E
    static let backgroundCard = Color(red: 0.15, green: 0.15, blue: 0.15) // #262626
    
    // Colores de acento principales
    static let accentRed = Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30 (rojo vibrante)
    static let accentOrange = Color(red: 1.0, green: 0.58, blue: 0.0) // #FF9500
    static let accentBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    static let accentGreen = Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759
    static let accentPurple = Color(red: 0.69, green: 0.32, blue: 0.87) // #AF52DE
    
    // Colores de texto
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.68, green: 0.68, blue: 0.70) // #AEAEB2
    static let textTertiary = Color(red: 0.48, green: 0.48, blue: 0.50) // #7C7C80
    
    // Colores de estado
    static let success = accentGreen
    static let warning = accentOrange
    static let error = accentRed
    static let danger = accentRed
    static let info = accentBlue
    
    // Colores adicionales
    static let secondaryGray = Color(red: 0.44, green: 0.44, blue: 0.46) // #707074
    
    // MARK: - Funciones de compatibilidad con el código existente
    
    static func primary(themeManager: ThemeManager) -> Color {
        return accentRed
    }
    
    static func cardBackground(isDark: Bool) -> Color {
        return backgroundCard
    }
    
    static func textPrimary(isDark: Bool) -> Color {
        return textPrimary
    }
    
    static func background(isDark: Bool) -> Color {
        return backgroundPrimary
    }
    
    static func textSecondary(isDark: Bool) -> Color {
        return textSecondary
    }
    
    // MARK: - Gradientes modernos
    
    static let primaryGradient = LinearGradient(
        colors: [accentRed, accentOrange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [backgroundCard, backgroundSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let blueGradient = LinearGradient(
        colors: [accentBlue, accentPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Colores específicos para las tarjetas del dashboard
    
    static let streakCardColor = accentRed
    static let bestDayCardColor = accentOrange
    static let exercisesCardColor = accentBlue
    static let timeCardColor = accentGreen

    // MARK: - Colores adicionales para el calendario moderno
    static let orange = accentOrange
    static let purple = accentPurple
    static let pink = Color(red: 1.0, green: 0.18, blue: 0.33) // #FF2D55

    // Alias para compatibilidad
    static let blue = accentBlue
    static let green = accentGreen
    static let red = accentRed
}
