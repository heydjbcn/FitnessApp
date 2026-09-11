//
//  WorkoutViewModel+TimeBudget.swift
//  ChamaFit
//
//  «Salgo a las 19:10»: cuánto te queda con tus tiempos reales (serie más
//  descanso, sacado del historial) y, si no da, qué recortar: primero series
//  de aislamiento, luego las últimas de los compuestos, luego aislamientos
//  enteros. El ejercicio principal nunca se toca. También «hoy me cuesta».
//

import Foundation
import Combine

struct TimeCut: Identifiable, Equatable {
    let id: UUID          // registro
    let name: String
    let from: Int
    let to: Int           // 0 = fuera hoy
}

struct TimePlan: Equatable {
    let neededSeconds: Double
    let availableSeconds: Double
    let finishAt: Date
    let cuts: [TimeCut]
    var fits: Bool { neededSeconds <= availableSeconds }
}

extension WorkoutViewModel {

    // MARK: - Cuánto tardas

    /// Segundos por serie (serie + descanso) según tu historial: la mediana de
    /// los huecos entre series del mismo día. Sin datos, descanso + trabajo.
    func secondsPerSet(_ ex: Exercise) -> Double {
        let cal = Calendar.current
        let byDay = Dictionary(grouping: allSetLogs(for: ex.id)) { cal.startOfDay(for: $0.date) }
        var gaps: [Double] = []
        for logs in byDay.values {
            let dates = logs.map(\.date).sorted()
            for (a, b) in zip(dates, dates.dropFirst()) {
                let g = b.timeIntervalSince(a)
                if g >= 20 && g <= 600 { gaps.append(g) }
            }
        }
        if gaps.count >= 3 {
            let s = gaps.suffix(40).sorted()
            return s[s.count / 2]
        }
        let work = ex.segundos > 0 ? Double(ex.segundos) : Double(max(1, ex.repetitions)) * 3 + 10
        return max(45, Double(ex.restDuration) + work)
    }

    /// Lo que queda de la sesión con esas series previstas (por registro).
    func remainingSeconds(_ day: WorkoutDay, targets: [UUID: Int]? = nil) -> Double {
        (dailyWorkoutRecords[day] ?? []).reduce(0) { total, r in
            guard let ex = getExercise(by: r.exerciseId) else { return total }
            let planned = targets?[r.id] ?? r.planned(ex)
            let left = max(0, planned - r.completedSets)
            guard left > 0 else { return total }
            // La última serie no lleva descanso; empezar un ejercicio nuevo, un minuto de cambio.
            let rest = Double(ex.restDuration)
            return total + Double(left) * secondsPerSet(ex) - min(rest, secondsPerSet(ex) * 0.5) + (r.completedSets == 0 ? 60 : 0)
        }
    }

    /// Minutos que quedan (redondeando hacia arriba).
    func remainingMinutesEstimate(for day: WorkoutDay) -> Int { Int((remainingSeconds(day) / 60).rounded(.up)) }

    /// Compuesto: mueve varias articulaciones (en el catálogo, con dos o más grupos secundarios).
    func isCompound(_ ex: Exercise) -> Bool {
        (ExerciseLibrary.details(for: ex.name)?.secondary.count ?? 0) >= 2
    }

    /// El principal del día: el primer compuesto de la lista (o el primero a secas).
    func mainRecord(_ day: WorkoutDay) -> WorkoutExercise? {
        let recs = dailyWorkoutRecords[day] ?? []
        return recs.first { getExercise(by: $0.exerciseId).map(isCompound) ?? false } ?? recs.first
    }

    // MARK: - Hora límite

    func timePlan(for day: WorkoutDay, until deadline: Date, now: Date = Date()) -> TimePlan {
        let recs = dailyWorkoutRecords[day] ?? []
        var targets: [UUID: Int] = [:]
        for r in recs { targets[r.id] = plannedSets(r) }
        let available = max(0, deadline.timeIntervalSince(now))
        func fits() -> Bool { remainingSeconds(day, targets: targets) <= available }
        let mainId = mainRecord(day)?.id
        let pending = recs.filter { r in (targets[r.id] ?? 0) > r.completedSets && r.id != mainId }
        let iso = pending.filter { !(getExercise(by: $0.exerciseId).map(isCompound) ?? false) }
        let comp = pending.filter { getExercise(by: $0.exerciseId).map(isCompound) ?? false }

        // 1 y 2: una serie menos (sin bajar de 2 ni de lo ya hecho), empezando por el final.
        for group in [iso, comp] where !fits() {
            for r in group.reversed() where !fits() {
                let t = targets[r.id] ?? 0
                if t - 1 >= max(2, r.completedSets) { targets[r.id] = t - 1 }
            }
        }
        // 3 y 4: fuera los que no se han empezado, del último al primero.
        for group in [iso, comp] where !fits() {
            for r in group.reversed() where !fits() && r.completedSets == 0 {
                targets[r.id] = 0
            }
        }
        let cuts: [TimeCut] = recs.compactMap { r in
            guard let ex = getExercise(by: r.exerciseId), let t = targets[r.id], t != plannedSets(r) else { return nil }
            return TimeCut(id: r.id, name: ex.name, from: plannedSets(r), to: t)
        }
        let needed = remainingSeconds(day, targets: targets)
        return TimePlan(neededSeconds: needed, availableSeconds: available,
                        finishAt: now.addingTimeInterval(needed), cuts: cuts)
    }

    /// La hora límite de hoy, si se puso.
    var sessionDeadline: Date? {
        get {
            guard let d = userDefaults.object(forKey: "SessionDeadline") as? Date,
                  Calendar.current.isDateInToday(d) else { return nil }
            return d
        }
        set {
            if let newValue { userDefaults.set(newValue, forKey: "SessionDeadline") }
            else { userDefaults.removeObject(forKey: "SessionDeadline") }
            objectWillChange.send()
        }
    }

    func applyTimePlan(_ plan: TimePlan, day: WorkoutDay, deadline: Date) {
        ensureSession()
        guard var recs = dailyWorkoutRecords[day] else { return }
        for cut in plan.cuts {
            if let i = recs.firstIndex(where: { $0.id == cut.id }) { recs[i].targetSets = cut.to }
        }
        dailyWorkoutRecords[day] = recs
        sessionDeadline = deadline
        recordHistory(for: day)
        persistAll()
        publishSummary()
        PhoneConnectivity.shared.sendTodayContext()
    }

    /// Quita recortes y hora límite: vuelven las series de siempre.
    func clearSessionTargets(_ day: WorkoutDay) {
        guard var recs = dailyWorkoutRecords[day] else { return }
        for i in recs.indices { recs[i].targetSets = nil }
        dailyWorkoutRecords[day] = recs
        sessionDeadline = nil
        setLight(false)
        recordHistory(for: day)
        persistAll()
        publishSummary()
        PhoneConnectivity.shared.sendTodayContext()
    }

    /// ¿Vas tarde para la hora límite? (con dos minutos de margen)
    func isRunningLate(_ day: WorkoutDay, now: Date = Date()) -> Bool {
        guard let d = sessionDeadline else { return false }
        return now.addingTimeInterval(remainingSeconds(day)) > d.addingTimeInterval(120)
    }

    // MARK: - «Hoy me cuesta»

    private var lightDays: [Date] {
        get { (userDefaults.array(forKey: "LightDays") as? [Date]) ?? [] }
        set { userDefaults.set(Array(newValue.suffix(200)), forKey: "LightDays") }
    }

    func isLightDay(_ date: Date) -> Bool {
        let d = Calendar.current.startOfDay(for: date)
        return lightDays.contains(d)
    }

    var isLightToday: Bool { isLightDay(Date()) }

    private func setLight(_ on: Bool) {
        let today = Calendar.current.startOfDay(for: Date())
        var days = lightDays.filter { $0 != today }
        if on { days.append(today) }
        lightDays = days
        objectWillChange.send()
    }

    /// Versión ligera: una serie menos en todo, fuera los aislamientos sin
    /// empezar; lo hecho se queda. El peso sugerido baja un 10 % y la sesión
    /// no cuenta para decidir si estás estancado.
    func lightenSession(_ day: WorkoutDay) {
        ensureSession()
        guard var recs = dailyWorkoutRecords[day] else { return }
        let mainId = mainRecord(day)?.id
        for i in recs.indices {
            guard let ex = getExercise(by: recs[i].exerciseId) else { continue }
            let planned = recs[i].planned(ex)
            if !isCompound(ex) && recs[i].completedSets == 0 && recs[i].id != mainId && recs.count > 2 {
                recs[i].targetSets = 0
            } else {
                recs[i].targetSets = max(1, recs[i].completedSets, planned - 1)
            }
        }
        dailyWorkoutRecords[day] = recs
        setLight(true)
        recordHistory(for: day)
        persistAll()
        publishSummary()
        PhoneConnectivity.shared.sendTodayContext()
    }
}
