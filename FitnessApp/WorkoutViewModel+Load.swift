//
//  WorkoutViewModel+Load.swift
//  ChamaFit
//
//  Cuentas que dependen del tipo de carga: tonelaje, récords y cómo se
//  enseña un peso («2 × 20 kg», «20 kg por lado», «asist. 15 kg»).
//

import Foundation

extension WorkoutViewModel {

    func loadKind(for exerciseId: UUID) -> LoadKind { getExercise(by: exerciseId)?.loadKind ?? .total }

    /// Peso corporal registrado en esa fecha o antes (si no, el primero que haya).
    func bodyWeight(on date: Date) -> Double? {
        var best: (Date, Double)? = nil
        var earliest: (Date, Double)? = nil
        for (d, kg) in bodyWeightHistory {
            if d <= date, best == nil || d > best!.0 { best = (d, kg) }
            if earliest == nil || d < earliest!.0 { earliest = (d, kg) }
        }
        return (best ?? earliest)?.1
    }

    /// Kilos de verdad movidos en una serie.
    func volume(_ log: SetLog, kind: LoadKind) -> Double {
        let reps = Double(log.reps)
        switch kind {
        case .total: return log.weight * reps
        case .perDumbbell, .perSide: return 2 * log.weight * reps
        case .bodyweight: return ((bodyWeight(on: log.date) ?? 0) + log.weight) * reps
        case .assisted:
            guard let bw = bodyWeight(on: log.date) else { return 0 }
            return max(0, bw - log.weight) * reps
        }
    }

    func volume(_ logs: [SetLog], exerciseId: UUID) -> Double {
        let kind = loadKind(for: exerciseId)
        return logs.reduce(0) { $0 + volume($1, kind: kind) }
    }

    func volume(of records: [WorkoutExercise]) -> Double {
        records.reduce(0) { $0 + volume($1.setLogs, exerciseId: $1.exerciseId) }
    }

    /// ¿`a` supera a `b` para este tipo de carga?
    static func beats(_ a: Double, _ b: Double, kind: LoadKind) -> Bool {
        kind.lowerIsBetter ? a < b : a > b
    }

    /// El mejor de una lista de pesos según el tipo de carga.
    static func best(_ weights: [Double], kind: LoadKind) -> Double? {
        kind.lowerIsBetter ? weights.min() : weights.max()
    }

    /// "60 kg", "2 × 20 kg", "20 kg por lado", "asist. 15 kg", "corporal + 10 kg".
    static func weightText(_ kg: Double, kind: LoadKind) -> String {
        switch kind {
        case .total: return Units.format(kg)
        case .perDumbbell: return "2 × \(Units.format(kg))"
        case .perSide: return String(localized: "\(Units.format(kg)) por lado")
        case .assisted: return kg > 0 ? String(localized: "asist. \(Units.format(kg))") : "sin asistencia".loc
        case .bodyweight: return kg > 0 ? String(localized: "corporal + \(Units.format(kg))") : "peso corporal".loc
        }
    }

    func weightText(_ kg: Double, for exerciseId: UUID) -> String {
        Self.weightText(kg, kind: loadKind(for: exerciseId))
    }
}
