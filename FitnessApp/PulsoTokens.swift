//
//  PulsoTokens.swift
//  FitnessApp
//
//  Tokens del rediseño «Pulso». Es la fuente única de color, radio, sombra y
//  desenfoque: AppColors y CustomStyles se apoyan aquí, así que tocar un valor
//  en este fichero cambia la app entera.
//
//  Los valores vienen del prototipo de Claude Design (ChamaFit.dc.html).
//

import SwiftUI

enum Pulso {

    // MARK: - Superficies

    /// Fondo de la app. Oscuro casi negro con tinte violeta; claro lavanda muy pálido.
    static func background(isDark: Bool) -> Color {
        isDark ? Color(hex: "#0B0A14") : Color(hex: "#F5F4FB")
    }

    /// Tarjeta de cristal. En oscuro es blanco translúcido sobre el fondo; en claro, blanco sólido.
    static func card(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.06) : Color(hex: "#FFFFFF")
    }

    /// Superficie secundaria: chips, campos, celdas dentro de una tarjeta.
    static func soft(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.10) : Color(hex: "#ECEAF6")
    }

    /// Línea divisoria y borde de tarjeta.
    static func line(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.10) : Color(hex: "#E2E0EE")
    }

    /// Fondo de la barra de pestañas (translúcido, va con desenfoque detrás).
    static func navBar(isDark: Bool) -> Color {
        isDark ? Color(hex: "#141224").opacity(0.80) : Color.white.opacity(0.86)
    }

    // MARK: - Tinta

    /// Texto principal.
    static func ink(isDark: Bool) -> Color {
        isDark ? Color(hex: "#F4F3FF") : Color(hex: "#15132A")
    }

    /// Texto secundario / apagado.
    static func mute(isDark: Bool) -> Color {
        isDark ? Color(hex: "#8E8CA8") : Color(hex: "#6E6C86")
    }

    /// Texto terciario: unidades, marcas de agua, texto deshabilitado.
    static func faint(isDark: Bool) -> Color {
        mute(isDark: isDark).opacity(0.6)
    }

    // MARK: - Estado

    static func danger(isDark: Bool) -> Color {
        isDark ? Color(hex: "#FB7185") : Color(hex: "#DC2626")
    }

    static func ok(isDark: Bool) -> Color {
        isDark ? Color(hex: "#34D399") : Color(hex: "#059669")
    }

    static func warning(isDark: Bool) -> Color {
        isDark ? Color(hex: "#FBBF24") : Color(hex: "#B45309")
    }

    // MARK: - Geometría

    enum Radius {
        static let pill: CGFloat = 999
        static let card: CGFloat = 22
        static let cardLarge: CGFloat = 26
        static let panel: CGFloat = 18
        static let control: CGFloat = 16
        static let chip: CGFloat = 14
        static let small: CGFloat = 12
    }

    enum Space {
        static let screen: CGFloat = 20   // margen lateral de pantalla
        static let card: CGFloat = 18     // padding interior de tarjeta
        static let stack: CGFloat = 14    // separación entre tarjetas
        static let tight: CGFloat = 8
    }

    /// Radio del desenfoque de cristal.
    static let glassBlur: CGFloat = 22

    // MARK: - Sombra y resplandor

    /// Sombra suave bajo las tarjetas.
    static func cardShadow(isDark: Bool) -> Color {
        isDark ? Color.black.opacity(0.45) : Color.black.opacity(0.06)
    }

    /// Resplandor del acento detrás de lo que está activo.
    static func glow(_ accent: AccentColor, isDark: Bool) -> Color {
        accent.gradientColors(isDark: isDark).first!.opacity(isDark ? 0.50 : 0.22)
    }
}

// MARK: - Acentos con degradado

extension AccentColor {

    /// Los dos extremos del degradado del acento, según el tema.
    /// El prototipo define una pareja distinta para claro y para oscuro: en claro
    /// los tonos se oscurecen para que el texto encima siga leyéndose.
    func gradientColors(isDark: Bool) -> [Color] {
        let hexes: (dark: [String], light: [String])
        switch self {
        case .purple: hexes = (["#8B5CF6", "#22D3EE"], ["#6D28D9", "#0E7490"]) // Violeta
        case .red:    hexes = (["#FF6B81", "#FFB020"], ["#E11D48", "#C2410C"]) // Coral
        case .green:  hexes = (["#A3FF12", "#2DD4BF"], ["#4D7C0F", "#0F766E"]) // Lima
        case .pink:   hexes = (["#F472B6", "#A78BFA"], ["#DB2777", "#7C3AED"]) // Rosa
        case .orange: hexes = (["#FBBF24", "#FB7185"], ["#B45309", "#DC2626"]) // Ámbar
        case .blue:   hexes = (["#60A5FA", "#22D3EE"], ["#2563EB", "#0E7490"]) // Azul
        // Heredados: no aparecen en el selector, pero siguen resolviendo para
        // quien los tuviera guardados de la versión anterior.
        case .teal:   hexes = (["#2DD4BF", "#60A5FA"], ["#0F766E", "#2563EB"])
        case .indigo: hexes = (["#818CF8", "#22D3EE"], ["#4338CA", "#0E7490"])
        }
        return (isDark ? hexes.dark : hexes.light).map { Color(hex: $0) }
    }

    /// Degradado listo para usar como relleno.
    func gradient(isDark: Bool) -> LinearGradient {
        LinearGradient(colors: gradientColors(isDark: isDark),
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Color plano del acento, para texto e iconos sueltos.
    /// En oscuro es el tono vivo; en claro, el oscurecido que contrasta con el fondo pálido.
    func accent(isDark: Bool) -> Color {
        switch self {
        case .purple: return Color(hex: isDark ? "#22D3EE" : "#6D28D9")
        case .red:    return Color(hex: isDark ? "#FF6B81" : "#E11D48")
        case .green:  return Color(hex: isDark ? "#A3FF12" : "#4D7C0F")
        case .pink:   return Color(hex: isDark ? "#F472B6" : "#DB2777")
        case .orange: return Color(hex: isDark ? "#FBBF24" : "#B45309")
        case .blue:   return Color(hex: isDark ? "#60A5FA" : "#2563EB")
        case .teal:   return Color(hex: isDark ? "#2DD4BF" : "#0F766E")
        case .indigo: return Color(hex: isDark ? "#818CF8" : "#4338CA")
        }
    }

    /// Color legible ENCIMA del acento.
    func onAccent(isDark: Bool) -> Color {
        isDark ? Color(hex: "#0B0A14") : .white
    }

    /// Los seis acentos que ofrece el selector de Ajustes, en el orden del diseño.
    static var selectable: [AccentColor] { [.purple, .red, .green, .pink, .orange, .blue] }
}
