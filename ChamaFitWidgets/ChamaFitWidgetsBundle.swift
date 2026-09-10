//
//  ChamaFitWidgetsBundle.swift
//  ChamaFitWidgets
//
//  La extensión de widgets: la Live Activity del descanso (pantalla bloqueada,
//  Dynamic Island y Smart Stack del Apple Watch) y el widget de la sesión de hoy.
//

import SwiftUI
import WidgetKit

@main
struct ChamaFitWidgetsBundle: WidgetBundle {
    var body: some Widget {
        RestLiveActivity()
        TodayWidget()
    }
}

// MARK: - Estilo compartido por los widgets

enum WidgetStyle {
    static func color(_ hex: String) -> Color {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        return Color(red: Double((rgb >> 16) & 0xFF) / 255, green: Double((rgb >> 8) & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255)
    }

    static func gradient(_ a: String, _ b: String, horizontal: Bool = false) -> LinearGradient {
        LinearGradient(colors: [color(a), color(b)],
                       startPoint: horizontal ? .leading : .topLeading,
                       endPoint: horizontal ? .trailing : .bottomTrailing)
    }

    static let bg = Color(red: 11/255, green: 10/255, blue: 20/255)      // #0B0A14
    static let ink = Color(red: 244/255, green: 243/255, blue: 255/255)  // #F4F3FF
    static let mute = Color(red: 142/255, green: 140/255, blue: 168/255) // #8E8CA8
    static let soft = Color.white.opacity(0.10)

    static func onAccent(_ dark: Bool) -> Color { dark ? bg : .white }
}
