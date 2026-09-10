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

    init(dayName: String, sessionLabel: String?, exerciseCount: Int, doneSets: Int, totalSets: Int,
         nextExercise: String?, streak: Int, accent1: String, accent2: String, onAccentDark: Bool,
         updatedAt: Date = Date()) {
        self.dayName = dayName; self.sessionLabel = sessionLabel; self.exerciseCount = exerciseCount
        self.doneSets = doneSets; self.totalSets = totalSets; self.nextExercise = nextExercise
        self.streak = streak; self.accent1 = accent1; self.accent2 = accent2
        self.onAccentDark = onAccentDark; self.updatedAt = updatedAt
    }

    /// Tolerante: el widget y la app pueden ir en versiones distintas un rato.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dayName = try c.decodeIfPresent(String.self, forKey: .dayName) ?? ""
        sessionLabel = try c.decodeIfPresent(String.self, forKey: .sessionLabel)
        exerciseCount = try c.decodeIfPresent(Int.self, forKey: .exerciseCount) ?? 0
        doneSets = try c.decodeIfPresent(Int.self, forKey: .doneSets) ?? 0
        totalSets = try c.decodeIfPresent(Int.self, forKey: .totalSets) ?? 0
        nextExercise = try c.decodeIfPresent(String.self, forKey: .nextExercise)
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        accent1 = try c.decodeIfPresent(String.self, forKey: .accent1) ?? "#7C5CFF"
        accent2 = try c.decodeIfPresent(String.self, forKey: .accent2) ?? "#3CC9FF"
        onAccentDark = try c.decodeIfPresent(Bool.self, forKey: .onAccentDark) ?? false
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

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
