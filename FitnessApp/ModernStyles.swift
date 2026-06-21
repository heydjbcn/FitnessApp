//
//  ModernStyles.swift
//  FitnessApp
//
//  Modern UI Styles for the fitness app
//

import SwiftUI

// MARK: - Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    let isDarkMode: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal)
            .frame(height: 44)
            .background(AppColors.cardBackground(isDark: isDarkMode))
            .cornerRadius(16)
            .foregroundColor(AppColors.textPrimary(isDark: isDarkMode))
            .shadow(color: Color.black.opacity(isDarkMode ? 0.2 : 0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Card Style Modifier
struct CardStyle: ViewModifier {
    let isDarkMode: Bool
    
    func body(content: Content) -> some View {
        content
            .background(AppColors.cardBackground(isDark: isDarkMode))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    let themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(AppColors.primary(themeManager: themeManager))
            .foregroundColor(.white)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: AppColors.primary(themeManager: themeManager).opacity(0.2), radius: 6, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Rest Duration Button Style
struct RestDurationButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isDarkMode: Bool
    let themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundColor(isSelected ? Color.white : AppColors.textPrimary(isDark: isDarkMode))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppColors.primary(themeManager: themeManager) : AppColors.cardBackground(isDark: isDarkMode))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.primary(themeManager: themeManager), lineWidth: isSelected ? 0 : 1)
                    )
            )
    }
}

// MARK: - View Extensions
extension View {
    func addFocusGlow(isFocused: Bool, themeManager: ThemeManager? = nil) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? AppColors.accentRed : Color.clear, lineWidth: 2)
            )
            .shadow(color: AppColors.accentRed.opacity(isFocused ? 0.12 : 0), radius: 6)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    func modernCardStyle(isDarkMode: Bool = false) -> some View {
        self.modifier(CardStyle(isDarkMode: isDarkMode))
    }
}

// MARK: - Close Button Component
struct CloseButton: View {
    let action: () -> Void
    let themeManager: ThemeManager?
    
    init(action: @escaping () -> Void, themeManager: ThemeManager? = nil) {
        self.action = action
        self.themeManager = themeManager
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.title3.weight(.bold))
                .foregroundColor(AppColors.accentRed)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.1))
                        .overlay(Circle().stroke(Color.clear, lineWidth: 1))
                )
        }
    }
}

// MARK: - Additional View Extensions
extension View {
    func cardStyle(isDarkMode: Bool) -> some View {
        self
            .background(AppColors.cardBackground(isDark: isDarkMode))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
    }
}
//
//  ModernStyles.swift
//  FitnessApp
//
//  Estilos modernos para la aplicación
//  Created by Jordi Mauri on 30/7/25.
//

import SwiftUI

// MARK: - Modern View Modifiers

// Estilo de tarjeta moderna  
struct ModernCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.backgroundCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// Estilo con gradiente moderno
struct ModernGradientModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.primaryGradient)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// Estilo de tarjeta de estadística
struct StatCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.backgroundCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - View Extensions
extension View {
    func modernCard() -> some View {
        self.modifier(ModernCardModifier())
    }
    
    func modernGradient() -> some View {
        self.modifier(ModernGradientModifier())
    }
    
    func statCard() -> some View {
        self.modifier(StatCardModifier())
    }
    
    func glassEffect() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.backgroundCard.opacity(0.8))
                    .background(.ultraThinMaterial)
            )
    }
}