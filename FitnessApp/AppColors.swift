import SwiftUI
import Combine

// MARK: - Helper hex
extension Color {
    /// Crea un Color desde "#RRGGBB" o "RRGGBB".
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// Enum para el tema
enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
}

struct AppColors {
    // MARK: - Paleta (rediseño 2026, dark-first, acento lima eléctrico)
    static let limeAccent   = Color(hex: "#C6F542")
    static let accentLime    = Color(hex: "#C6F542")
    static let accentBlue    = Color(hex: "#3B82F6")
    static let accentPurple  = Color(hex: "#A855F7")
    static let accentOrange  = Color(hex: "#F97316")
    static let accentRed     = Color(hex: "#EF4444")
    static let accentPink    = Color(hex: "#EC4899")
    static let accentTeal    = Color(hex: "#14B8A6")
    static let accentIndigo  = Color(hex: "#6366F1")

    // Fondos / superficies
    static let bgDark    = Color(hex: "#0B0D0F")
    static let surfaceDark = Color(hex: "#16191D")
    static let cardDark  = Color(hex: "#1F242A")
    static let bgLight   = Color(hex: "#F2F4F2")
    static let cardLight = Color(hex: "#FFFFFF")

    // MARK: - Color primario (acento del usuario)
    static func primary(themeManager: ThemeManager) -> Color {
        themeManager.selectedAccentColor.color
    }
    static func primaryDynamic(themeManager: ThemeManager) -> Color {
        themeManager.selectedAccentColor.color
    }
    /// Color de texto/icono legible sobre el acento (contraste correcto).
    static func onPrimary(themeManager: ThemeManager) -> Color {
        themeManager.selectedAccentColor.onColor
    }
    /// Texto oscuro para usar sobre el acento lima por defecto.
    static let onAccentDark = Color(hex: "#0B0D0F")
    static let primary = accentLime  // fallback estático

    // MARK: - Colores dinámicos por isDark
    static func background(isDark: Bool) -> Color {
        isDark ? bgDark : bgLight
    }
    static func surface(isDark: Bool) -> Color {
        isDark ? surfaceDark : Color(hex: "#F2F4EE")
    }
    static func cardBackground(isDark: Bool) -> Color {
        isDark ? cardDark : cardLight
    }
    static func textPrimary(isDark: Bool) -> Color {
        isDark ? Color(hex: "#F2F4F2") : Color(hex: "#0B0D0F")
    }
    static func textSecondary(isDark: Bool) -> Color {
        isDark ? Color(hex: "#8B929B") : Color(hex: "#565D66")
    }
    static func textTertiary(isDark: Bool) -> Color {
        isDark ? Color(hex: "#565D66") : Color(hex: "#8B929B")
    }
    static func hairline(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
    }

    // MARK: - Compatibilidad con AppTheme
    static func background(for theme: AppTheme) -> Color { background(isDark: theme == .dark) }
    static func cardBackground(for theme: AppTheme) -> Color { cardBackground(isDark: theme == .dark) }
    static func textPrimary(for theme: AppTheme) -> Color { textPrimary(isDark: theme == .dark) }
    static func textSecondary(for theme: AppTheme) -> Color { textSecondary(isDark: theme == .dark) }

    // MARK: - Colores estáticos / estado
    static let secondaryGray = Color(hex: "#565D66")
    static let accentCyan = accentTeal
    static let danger  = accentRed
    static let success = accentLime
    static let warning = accentOrange

    // Estáticos "por defecto" (dark-first)
    static let background     = bgDark
    static let cardBackground = cardDark
    static let textPrimary    = Color(hex: "#F2F4F2")
    static let textSecondary  = Color(hex: "#8B929B")

    // Gradientes
    static let primaryGradient = LinearGradient(
        colors: [accentLime, accentTeal], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct AppFonts {
    private static func space(_ size: CGFloat, _ w: String) -> Font { .custom("SpaceGrotesk-\(w)", size: size) }
    private static func hanken(_ size: CGFloat, _ w: String) -> Font { .custom("HankenGrotesk-\(w)", size: size) }

    // Space Grotesk → títulos / datos
    static let title    = space(22, "Bold")
    static let subtitle = space(16, "SemiBold")
    // Hanken Grotesk → cuerpo / etiquetas
    static let body     = hanken(15, "Regular")
    static let caption  = hanken(13, "Regular")

    // Extras útiles para el rediseño (números/métricas y títulos grandes)
    static let largeTitle = space(34, "Bold")
    static let title2     = space(28, "Bold")
    static let metric     = space(26, "Bold")
    static let bigMetric  = space(40, "Bold")
    static let bodyMedium = hanken(15, "Medium")
    static let label      = hanken(12, "SemiBold")
}
