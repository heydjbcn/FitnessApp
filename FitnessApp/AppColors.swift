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

    /// "#RRGGBB" del color (para pasárselo al widget y al reloj).
    var hexString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
    }
}

/// Fachada de color de la app. Mantiene la API que ya usan las vistas, pero
/// por dentro resuelve todo contra los tokens de `Pulso`.
struct AppColors {
    // MARK: - Paleta de acentos (extremo vivo de cada degradado de «Pulso»)
    static let limeAccent    = Color(hex: "#A3FF12")
    static let accentLime    = Color(hex: "#A3FF12")
    static let accentBlue    = Color(hex: "#60A5FA")
    static let accentPurple  = Color(hex: "#8B5CF6")
    static let accentOrange  = Color(hex: "#FBBF24")
    static let accentRed     = Color(hex: "#FF6B81")
    static let accentPink    = Color(hex: "#F472B6")
    static let accentTeal    = Color(hex: "#22D3EE")
    static let accentIndigo  = Color(hex: "#818CF8")

    // Fondos / superficies
    static let bgDark      = Color(hex: "#0B0A14")
    static let surfaceDark = Color(hex: "#141224")
    static let cardDark    = Color(hex: "#17162A")
    static let bgLight     = Color(hex: "#F5F4FB")
    static let cardLight   = Color(hex: "#FFFFFF")

    // MARK: - Color primario (acento del usuario)
    static func primary(themeManager: ThemeManager) -> Color {
        themeManager.selectedAccentColor.accent(isDark: themeManager.isDarkMode)
    }
    static func primaryDynamic(themeManager: ThemeManager) -> Color {
        primary(themeManager: themeManager)
    }
    /// Color de texto/icono legible sobre el acento (contraste correcto).
    static func onPrimary(themeManager: ThemeManager) -> Color {
        themeManager.selectedAccentColor.onAccent(isDark: themeManager.isDarkMode)
    }
    /// Degradado del acento del usuario: el relleno estrella del diseño.
    static func primaryGradient(themeManager: ThemeManager) -> LinearGradient {
        themeManager.selectedAccentColor.gradient(isDark: themeManager.isDarkMode)
    }
    /// Texto oscuro para usar sobre un acento claro.
    static let onAccentDark = Color(hex: "#0B0A14")
    static let primary = accentTeal  // fallback estático

    // MARK: - Colores dinámicos por isDark
    static func background(isDark: Bool) -> Color { Pulso.background(isDark: isDark) }
    static func surface(isDark: Bool) -> Color { Pulso.soft(isDark: isDark) }
    static func cardBackground(isDark: Bool) -> Color { Pulso.card(isDark: isDark) }
    static func textPrimary(isDark: Bool) -> Color { Pulso.ink(isDark: isDark) }
    static func textSecondary(isDark: Bool) -> Color { Pulso.mute(isDark: isDark) }
    static func textTertiary(isDark: Bool) -> Color { Pulso.faint(isDark: isDark) }
    static func hairline(isDark: Bool) -> Color { Pulso.line(isDark: isDark) }

    // MARK: - Colores estáticos / estado
    static let secondaryGray = Color(hex: "#6E6C86")
    static let accentCyan = accentTeal
    static func danger(isDark: Bool) -> Color { Pulso.danger(isDark: isDark) }
    static func success(isDark: Bool) -> Color { Pulso.ok(isDark: isDark) }
    static func warning(isDark: Bool) -> Color { Pulso.warning(isDark: isDark) }
    static let danger  = Color(hex: "#FB7185")
    static let success = Color(hex: "#34D399")
    static let warning = Color(hex: "#FBBF24")

    // Estáticos "por defecto" (dark-first)
    static let background     = bgDark
    static let cardBackground = cardDark
    static let textPrimary    = Color(hex: "#F4F3FF")
    static let textSecondary  = Color(hex: "#8E8CA8")

    // Gradiente por defecto (violeta → cian), para cuando no hay ThemeManager a mano
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#8B5CF6"), Color(hex: "#22D3EE")],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// Tipografía de «Pulso»: Bricolage Grotesque en los titulares y los números
/// grandes, Figtree en todo el texto corrido.
struct AppFonts {
    private static func display(_ size: CGFloat, _ w: String = "Bold") -> Font {
        .custom("BricolageGrotesque-\(w)", size: size)
    }
    private static func text(_ size: CGFloat, _ w: String) -> Font {
        .custom("Figtree-\(w)", size: size)
    }

    // Titulares / datos
    static let title    = display(22)
    static let subtitle = text(16, "SemiBold")
    // Cuerpo / etiquetas
    static let body     = text(15, "Regular")
    static let caption  = text(13, "Regular")

    // Números grandes y títulos de pantalla
    static let largeTitle = display(34, "ExtraBold")
    static let title2     = display(28, "ExtraBold")
    static let metric     = display(26)
    static let bigMetric  = display(40, "ExtraBold")
    static let bodyMedium = text(15, "Medium")
    static let label      = text(12, "SemiBold")
}
