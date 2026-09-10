//
//  WatchComplicationState.swift
//  ChamaFit Watch (app + complicaciones)
//
//  Lo que pintan las complicaciones de la esfera: la sesión de hoy, la serie
//  siguiente y el descanso. El reloj lo deja en el App Group cada vez que
//  cambia y pide a la esfera que se repinte.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct WatchComplicationState: Codable, Equatable {
    static let appGroup = "group.Mauri.FitnessApp"
    static let key = "WatchComplication"

    var dayName: String = ""
    var label: String = ""
    var done: Int = 0
    var total: Int = 0
    var next: String? = nil
    var restEnd: Date? = nil
    var accent1: String = "#8B5CF6"
    var accent2: String = "#22D3EE"
    var updatedAt: Date = Date()

    var progress: Double { total > 0 ? Double(done) / Double(total) : 0 }
    var resting: Bool { (restEnd ?? .distantPast) > Date() }

    static func load() -> WatchComplicationState? {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WatchComplicationState.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults(suiteName: Self.appGroup)?.set(data, forKey: Self.key)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
