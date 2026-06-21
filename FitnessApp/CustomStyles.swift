import SwiftUI

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

struct CardStyle: ViewModifier {
    let isDarkMode: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppColors.cardBackground(isDark: isDarkMode))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppColors.hairline(isDark: isDarkMode), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDarkMode ? 0.25 : 0.05), radius: 12, x: 0, y: 6)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let themeManager: ThemeManager

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.subtitle)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(AppColors.primary(themeManager: themeManager))
            .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: AppColors.primary(themeManager: themeManager).opacity(0.25), radius: 10, x: 0, y: 4)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct RestDurationButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isDarkMode: Bool
    let themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundColor(isSelected ? AppColors.onPrimary(themeManager: themeManager) : AppColors.textPrimary(isDark: isDarkMode))
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

extension View {
    func addFocusGlow(isFocused: Bool, themeManager: ThemeManager? = nil) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? (themeManager != nil ? AppColors.primary(themeManager: themeManager!) : AppColors.primary) : Color.clear, lineWidth: 2)
            )
            .shadow(color: (themeManager != nil ? AppColors.primary(themeManager: themeManager!) : AppColors.primary).opacity(isFocused ? 0.12 : 0), radius: 6)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    func cardStyle(isDarkMode: Bool = false) -> some View {
        self.modifier(CardStyle(isDarkMode: isDarkMode))
    }
}

// Componente reutilizable para botones de cierre (X)
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
                .foregroundColor(themeManager != nil ? AppColors.primary(themeManager: themeManager!) : AppColors.primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.1))
                        .overlay(Circle().stroke(Color.clear, lineWidth: 1))
                )
        }
    }
}