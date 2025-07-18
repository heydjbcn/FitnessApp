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
            .background(AppColors.cardBackground(isDark: isDarkMode))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(AppColors.primary)
            .foregroundColor(.white)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: AppColors.primary.opacity(0.2), radius: 6, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct RestDurationButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isDarkMode: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundColor(isSelected ? Color.black : AppColors.textPrimary(isDark: isDarkMode))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppColors.primary : AppColors.cardBackground(isDark: isDarkMode))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.primary, lineWidth: isSelected ? 0 : 1)
                    )
            )
    }
}

extension View {
    func addFocusGlow(isFocused: Bool) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .shadow(color: AppColors.primary.opacity(isFocused ? 0.12 : 0), radius: 6)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    func cardStyle(isDarkMode: Bool = false) -> some View {
        self.modifier(CardStyle(isDarkMode: isDarkMode))
    }
}

// Componente reutilizable para botones de cierre (X)
struct CloseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.title3.weight(.bold))
                .foregroundColor(AppColors.primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.1))
                        .overlay(Circle().stroke(Color.clear, lineWidth: 1))
                )
        }
    }
}