//
//  TodaySummary.swift
//  ChamaFit (app + ChamaFitWidgets)
//
//  Resumen de la sesión de hoy que la app deja en el App Group para que el
//  widget de pantalla de inicio lo pinte sin abrir la app.
//

import Foundation

struct TodaySummary: Codable, Equatable {
    static let appGroup = "group.Mauri.FitnessApp"
    static let key = "TodaySummary"

    var dayName: String          // "Jueves"
    var sessionLabel: String?    // "Hombro y core"
    var exerciseCount: Int
    var doneSets: Int
    var totalSets: Int
    var nextExercise: String?    // primer ejercicio con series pendientes
    var streak: Int
    var accent1: String
    var accent2: String
    var onAccentDark: Bool
    var updatedAt: Date = Date()

    var progress: Double { totalSets > 0 ? Double(doneSets) / Double(totalSets) : 0 }
    var isRestDay: Bool { exerciseCount == 0 }

    static func load() -> TodaySummary? {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(TodaySummary.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults(suiteName: Self.appGroup)?.set(data, forKey: Self.key)
    }
}
