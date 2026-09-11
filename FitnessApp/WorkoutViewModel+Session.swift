//
//  WorkoutViewModel+Session.swift
//  ChamaFit
//
//  Lo que necesita el modo entreno: qué ejercicio toca ahora (respetando
//  superseries), cuándo empezó la sesión y el resumen al terminar.
//

import Foundation

struct SessionSummary {
    struct Record: Equatable { let name: String; let weight: Double }
    struct Previous { let date: Date; let sets: Int; let volume: Double; let duration: TimeInterval }

    let day: WorkoutDay
    let label: String?
    let start: Date?
    let end: Date?
    let sets: Int
    let totalSets: Int
    let volume: Double
    let exercisesDone: Int
    let records: [Record]
    let previous: Previous?
    /// "Lunes" o, en secuencia, "Sesión B".
    var slot: String? = nil

    var slotName: String { slot ?? day.displayName }

    var duration: TimeInterval {
        guard let start, let end else { return 0 }
        return max(0, end.timeIntervalSince(start))
    }
}

extension WorkoutViewModel {

    /// El ejercicio que toca ahora en un día: el primero con series
    /// pendientes; dentro de una superserie, el que menos lleva (así se
    /// alternan A, B, A, B). Los saltados solo vuelven cuando no queda otro.
    func nextRecord(in day: WorkoutDay, skipping: Set<UUID> = []) -> WorkoutExercise? {
        let records = dailyWorkoutRecords[day] ?? []
        func pending(_ r: WorkoutExercise) -> Bool {
            guard let ex = getExercise(by: r.exerciseId) else { return false }
            if let g = r.supersetGroup, isBlockClosed(day, g) { return false }
            return r.completedSets < r.planned(ex)
        }
        let candidates = records.filter(pending)
        let pool = candidates.filter { !skipping.contains($0.id) }
        guard let first = (pool.isEmpty ? candidates : pool).first else { return nil }
        guard let g = first.supersetGroup else { return first }
        let group = (pool.isEmpty ? candidates : pool).filter { $0.supersetGroup == g }
        return group.min { $0.completedSets < $1.completedSets } ?? first
    }

    /// Primera y última serie marcadas hoy en ese día.
    func sessionBounds(for day: WorkoutDay) -> (start: Date, end: Date)? {
        let dates = (dailyWorkoutRecords[day] ?? []).flatMap(\.setLogs).map(\.date)
        guard let start = dates.min(), let end = dates.max() else { return nil }
        return (start, end)
    }

    /// "Press militar, 40 kilos por 8" para la voz y el descanso.
    func nextUpText(in day: WorkoutDay) -> String? {
        guard let rec = nextRecord(in: day), let ex = getExercise(by: rec.exerciseId) else { return nil }
        if ex.segundos > 0 { return String(localized: "\(ex.name), \(ex.segundos) segundos") }
        let s = proposedSet(for: ex, record: rec)
        return s.weight > 0
            ? String(localized: "\(ex.name), \(Units.number(s.weight)) \(WorkoutViewModel.unitWord) por \(s.reps)")
            : String(localized: "\(ex.name), \(s.reps) repeticiones")
    }

    func sessionSummary(for day: WorkoutDay, endedAt: Date? = nil) -> SessionSummary {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let records = dailyWorkoutRecords[day] ?? []
        let bounds = sessionBounds(for: day)

        var prs: [SessionSummary.Record] = []
        for r in records where !r.setLogs.isEmpty {
            guard let ex = getExercise(by: r.exerciseId) else { continue }
            let todayMax = r.setLogs.map(\.weight).max() ?? 0
            let before = allSetLogs(for: ex.id).filter { $0.date < today }.map(\.weight).max() ?? 0
            if before > 0 && todayMax > before { prs.append(.init(name: ex.name, weight: todayMax)) }
        }

        // La última vez que se entrenó este mismo día de rutina.
        var previous: SessionSummary.Previous? = nil
        if let entry = workoutHistory.filter({ $0.key < today && ($0.value[day]?.contains { $0.completedSets > 0 } ?? false) })
            .max(by: { $0.key < $1.key }), let recs = entry.value[day] {
            let logs = recs.flatMap(\.setLogs)
            let dates = logs.map(\.date)
            let dur = (dates.max() ?? entry.key).timeIntervalSince(dates.min() ?? entry.key)
            previous = .init(date: entry.key, sets: recs.reduce(0) { $0 + $1.completedSets },
                             volume: volume(of: recs), duration: dur)
        }

        let end = endedAt.map { max($0, bounds?.end ?? $0) } ?? bounds?.end
        return SessionSummary(day: day, label: label(for: day), start: bounds?.start, end: end,
                              sets: completedSets(for: day), totalSets: totalSets(for: day),
                              volume: volume(for: day),
                              exercisesDone: records.filter { $0.completedSets > 0 }.count,
                              records: prs, previous: previous, slot: slotName(day))
    }

    /// "1 h 05 min" / "42 min"
    static func durationText(_ seconds: TimeInterval) -> String {
        let m = Int(seconds / 60)
        return m >= 60 ? "\(m / 60) h \(String(format: "%02d", m % 60)) min" : String(localized: "\(max(1, m)) min")
    }

    /// "1,2 t" o "840 kg"
    static func tonnageText(_ kg: Double) -> String { Units.tonnage(kg) }

    /// "kilos" o "libras", para la voz.
    static var unitWord: String { (Units.weight == .kg ? "kilos" : "libras").loc }
}

extension WorkoutViewModel {
    /// Al pulsar «Terminar»: se refrescan widget y reloj (y, con permiso,
    /// se guarda en Salud: ver HealthManager).
    func sessionFinished(_ summary: SessionSummary) {
        publishSummary()
        PhoneConnectivity.shared.sendTodayContext()
        onSessionFinished?(summary)
    }
}
