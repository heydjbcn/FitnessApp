//
//  Experiments.swift
//  ChamaFit
//
//  Experimentos personales: dos condiciones (A y B) que se alternan por
//  sesión, por semana, por hora del día o por bloques, una métrica y un
//  resultado honesto: con pocos datos dice «aún no se puede saber» y solo
//  da un ganador si la diferencia es mayor que tu variación normal.
//

import Foundation
import Combine

enum ExperimentTemplate: String, Codable, CaseIterable, Identifiable {
    case rest, timeOfDay, supplement, custom
    var id: String { rawValue }

    var label: String {
        switch self {
        case .rest: return "¿Descansar más mejora mi fuerza?"
        case .timeOfDay: return "¿Rindo más por la mañana?"
        case .supplement: return "Un suplemento 4 semanas"
        case .custom: return "A tu medida"
        }
    }

    var detail: String {
        switch self {
        case .rest: return "Alterna 3 min de descanso con el tuyo de siempre en un ejercicio y compara su 1RM estimado."
        case .timeOfDay: return "Compara las sesiones antes de las 14:00 con las de la tarde."
        case .supplement: return "Cuatro semanas sin y cuatro con (creatina, cafeína…). Compara tu fuerza."
        case .custom: return "Tú pones las dos condiciones, cómo se alternan y qué se mide."
        }
    }

    var icon: String {
        switch self {
        case .rest: return "timer"
        case .timeOfDay: return "sunrise.fill"
        case .supplement: return "pills.fill"
        case .custom: return "flask.fill"
        }
    }
}

enum ExperimentMetric: String, Codable, CaseIterable, Identifiable {
    case e1rm, volume, rpe
    var id: String { rawValue }
    var label: String {
        switch self {
        case .e1rm: return "1RM estimado"
        case .volume: return "Tonelaje"
        case .rpe: return "RPE medio"
        }
    }
    var lowerIsBetter: Bool { self == .rpe }
}

enum ExperimentAlternation: String, Codable, CaseIterable, Identifiable {
    case bySession, byWeek, byTime, blocks
    var id: String { rawValue }
    var label: String {
        switch self {
        case .bySession: return "Una sesión cada una"
        case .byWeek: return "Una semana cada una"
        case .byTime: return "Mañana / tarde"
        case .blocks: return "Bloques (B primero, luego A)"
        }
    }
}

struct Experiment: Codable, Identifiable, Equatable {
    var id = UUID()
    var template: ExperimentTemplate
    var title: String
    var conditionA: String
    var conditionB: String
    var metric: ExperimentMetric
    /// Ejercicio que se mide (y al que se aplica el descanso). nil = toda la sesión.
    var exerciseId: UUID?
    var alternation: ExperimentAlternation
    /// Plantilla de descanso: segundos de la condición A.
    var restA: Int? = nil
    /// Semanas de cada bloque (o duración total en los demás).
    var weeks: Int = 4
    var start: Date
    var ended: Date? = nil
}

struct ExperimentResult: Equatable {
    var a: [Double]
    var b: [Double]
    var meanA: Double { a.isEmpty ? 0 : a.reduce(0, +) / Double(a.count) }
    var meanB: Double { b.isEmpty ? 0 : b.reduce(0, +) / Double(b.count) }
    var diffPct: Double { meanB == 0 ? 0 : (meanA - meanB) / meanB * 100 }
    var enough: Bool { a.count >= 3 && b.count >= 3 }
    /// Error típico de la diferencia de medias.
    var standardError: Double {
        func variance(_ x: [Double], _ m: Double) -> Double {
            x.count > 1 ? x.reduce(0) { $0 + ($1 - m) * ($1 - m) } / Double(x.count - 1) : 0
        }
        guard !a.isEmpty, !b.isEmpty else { return .infinity }
        return sqrt(variance(a, meanA) / Double(a.count) + variance(b, meanB) / Double(b.count))
    }
    /// ¿La diferencia supera a la variación normal (dos errores típicos)?
    var clear: Bool { enough && abs(meanA - meanB) > 2 * standardError }
}

extension WorkoutViewModel {

    var experiments: [Experiment] {
        get { userDefaults.data(forKey: "Experiments").flatMap { try? JSONDecoder().decode([Experiment].self, from: $0) } ?? [] }
        set {
            if let d = try? JSONEncoder().encode(newValue) { userDefaults.set(d, forKey: "Experiments") }
            objectWillChange.send()
        }
    }

    var activeExperiment: Experiment? { experiments.last { $0.ended == nil } }

    func startExperiment(_ e: Experiment) {
        var all = experiments.map { var x = $0; if x.ended == nil { x.ended = Date() }; return x }
        all.append(e)
        experiments = all
    }

    func endExperiment(_ id: UUID, now: Date = Date()) {
        experiments = experiments.map { var x = $0; if x.id == id && x.ended == nil { x.ended = now }; return x }
    }

    func deleteExperiment(_ id: UUID) { experiments = experiments.filter { $0.id != id } }

    // MARK: - Qué condición toca

    /// Sesiones (fechas con series; del ejercicio si el experimento tiene uno) desde el inicio.
    private func experimentDates(_ e: Experiment, upTo end: Date? = nil) -> [Date] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: e.start)
        let limit = end ?? e.ended ?? .distantFuture
        return workoutHistory.compactMap { date, byDay -> Date? in
            guard date >= start, date <= limit else { return nil }
            let recs = byDay.values.flatMap { $0 }.filter { $0.completedSets > 0 }
            if let ex = e.exerciseId { return recs.contains { $0.exerciseId == ex } ? date : nil }
            return recs.isEmpty ? nil : date
        }.sorted()
    }

    /// "A" o "B" para una sesión de esa fecha.
    func condition(_ e: Experiment, on date: Date) -> String {
        let cal = Calendar.current
        let d = cal.startOfDay(for: date)
        let weeksIn = max(0, cal.dateComponents([.day], from: cal.startOfDay(for: e.start), to: d).day ?? 0) / 7
        switch e.alternation {
        case .bySession:
            let before = experimentDates(e).filter { $0 < d }.count
            return before % 2 == 0 ? "A" : "B"
        case .byWeek:
            return weeksIn % 2 == 0 ? "A" : "B"
        case .blocks:
            return weeksIn < e.weeks ? "B" : "A"
        case .byTime:
            let first = (workoutHistory[d]?.values.flatMap { $0 }.flatMap(\.setLogs).map(\.date).min())
                ?? (cal.isDateInToday(d) ? Date() : d)
            return cal.component(.hour, from: first) < 14 ? "A" : "B"
        }
    }

    /// Descanso que manda el experimento de descanso hoy para ese ejercicio.
    func experimentRest(for exercise: Exercise, now: Date = Date()) -> Int? {
        guard let e = activeExperiment, e.template == .rest, e.exerciseId == exercise.id,
              let rest = e.restA, condition(e, on: now) == "A" else { return nil }
        return rest
    }

    // MARK: - Resultado

    func metricValue(_ e: Experiment, on date: Date) -> Double? {
        guard let byDay = workoutHistory[Calendar.current.startOfDay(for: date)] else { return nil }
        var recs = byDay.values.flatMap { $0 }.filter { $0.completedSets > 0 }
        if let ex = e.exerciseId { recs = recs.filter { $0.exerciseId == ex } }
        let work = recs.flatMap(\.setLogs).filter { $0.type == .normal || $0.type == .failure }
        guard !work.isEmpty else { return nil }
        switch e.metric {
        case .e1rm:
            let best = work.map(\.estimatedOneRepMax).max() ?? 0
            return best > 0 ? best : nil
        case .volume:
            let v = volume(of: recs)
            return v > 0 ? v : nil
        case .rpe:
            let r = work.compactMap(\.rpe)
            return r.isEmpty ? nil : Double(r.reduce(0, +)) / Double(r.count)
        }
    }

    func result(_ e: Experiment) -> ExperimentResult {
        var r = ExperimentResult(a: [], b: [])
        for d in experimentDates(e) {
            guard let v = metricValue(e, on: d) else { continue }
            if condition(e, on: d) == "A" { r.a.append(v) } else { r.b.append(v) }
        }
        return r
    }

    /// La conclusión en una frase, sin vender humo.
    func verdict(_ e: Experiment) -> String {
        let r = result(e)
        guard r.enough else {
            return String(localized: "Aún no se puede saber: llevas \(r.a.count) \((r.a.count == 1 ? "sesión" : "sesiones").loc) con A y \(r.b.count) con B. Hacen falta al menos 3 de cada.")
        }
        let pct = abs(r.diffPct)
        let pctText = AppLanguage.decimal(String(format: "%.1f", pct))
        guard r.clear else {
            return String(localized: "No se ve una diferencia clara: un \(pctText) % arriba o abajo cabe en tu variación normal entre sesiones.")
        }
        let aBetter = e.metric.lowerIsBetter ? r.meanA < r.meanB : r.meanA > r.meanB
        let winner = aBetter ? e.conditionA : e.conditionB
        let what = e.metric.lowerIsBetter ? "menos esfuerzo percibido" : String(localized: "más \(e.metric.label.lowercased())")
        return String(localized: "Con «\(winner)» consigues un \(pctText) % \(what), y la diferencia es mayor que tu variación normal.")
    }
}
