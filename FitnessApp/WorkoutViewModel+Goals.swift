//
//  WorkoutViewModel+Goals.swift
//  ChamaFit
//
//  Objetivos: sesiones por semana y un récord a alcanzar por ejercicio, con
//  la fecha estimada según la tendencia de las últimas 8 semanas. Si no hay
//  tendencia al alza, no se inventa ninguna fecha.
//

import Foundation
import Combine

struct GoalProgress: Equatable {
    let goal: Double
    let best: Double
    let eta: Date?

    var reached: Bool { best >= goal }
    var fraction: Double { goal > 0 ? min(1, best / goal) : 0 }
}

extension WorkoutViewModel {

    var weeklySessionGoal: Int {
        get { userDefaults.object(forKey: "WeeklyGoal") as? Int ?? 3 }
        set { userDefaults.set(min(7, max(1, newValue)), forKey: "WeeklyGoal"); objectWillChange.send() }
    }

    func setGoalWeight(_ kg: Double?, for exerciseId: UUID) {
        guard let i = availableExercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        availableExercises[i].goalWeight = (kg ?? 0) > 0 ? kg : nil
        persistAll()
    }

    func goalProgress(for ex: Exercise, now: Date = Date()) -> GoalProgress? {
        guard let goal = ex.goalWeight, goal > 0 else { return nil }
        let best = personalRecord(for: ex.id)?.weight ?? 0
        guard best < goal else { return GoalProgress(goal: goal, best: best, eta: nil) }
        let since = now.addingTimeInterval(-56 * 86_400)
        let points = exerciseDailyMaxWeight(for: ex.id).filter { $0.date >= since }.map { ($0.date, $0.weight) }
        return GoalProgress(goal: goal, best: best, eta: Self.linearETA(points: points, target: goal, now: now))
    }

    /// Recta de mínimos cuadrados sobre (día, peso máximo). Con al menos 3
    /// sesiones y pendiente positiva, cuándo llegaría al objetivo (máx. un año).
    static func linearETA(points: [(Date, Double)], target: Double, now: Date) -> Date? {
        guard points.count >= 3, let first = points.map(\.0).min() else { return nil }
        let xs = points.map { $0.0.timeIntervalSince(first) / 86_400 }
        let ys = points.map(\.1)
        let n = Double(points.count)
        let mx = xs.reduce(0, +) / n, my = ys.reduce(0, +) / n
        let sxx = xs.reduce(0) { $0 + ($1 - mx) * ($1 - mx) }
        guard sxx > 0 else { return nil }
        let slope = zip(xs, ys).reduce(0) { $0 + ($1.0 - mx) * ($1.1 - my) } / sxx
        guard slope > 0.001 else { return nil }
        let intercept = my - slope * mx
        let xNow = now.timeIntervalSince(first) / 86_400
        let days = max(7, (target - (intercept + slope * xNow)) / slope)
        guard days <= 365 else { return nil }
        return now.addingTimeInterval(days * 86_400)
    }
}
