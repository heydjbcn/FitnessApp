//
//  WorkoutViewModel+Schedule.swift
//  ChamaFit
//
//  Qué sesión toca hoy según cómo se reparte la rutina:
//   · Semana fija: cada sesión tiene su día (lo de siempre).
//   · Semana flexible: las sesiones de la semana, el día que puedas; lo que
//     no haces queda pendiente hasta el domingo y se propone la primera.
//   · Secuencia A/B/C: sin días; toca la siguiente a la última hecha.
//  Por dentro las sesiones siguen siendo los siete huecos `WorkoutDay`, así
//  historial, widgets, reloj y copias no cambian.
//

import Foundation
import Combine

enum ScheduleMode: String, Codable, CaseIterable, Identifiable {
    case fixedWeek, elasticWeek, sequence
    var id: String { rawValue }

    var label: String {
        switch self {
        case .fixedWeek: return "Semana fija"
        case .elasticWeek: return "Semana flexible"
        case .sequence: return "Secuencia A/B/C"
        }
    }

    var detail: String {
        switch self {
        case .fixedWeek: return "Cada sesión tiene su día de la semana."
        case .elasticWeek: return "Tus sesiones de la semana, el día que puedas. Lo que no hagas queda pendiente hasta el domingo."
        case .sequence: return "Sin días fijos: toca la siguiente a la última que hiciste."
        }
    }

    var icon: String {
        switch self {
        case .fixedWeek: return "calendar"
        case .elasticWeek: return "calendar.badge.clock"
        case .sequence: return "arrow.triangle.2.circlepath"
        }
    }
}

extension WorkoutViewModel {

    static let scheduleModeKey = "RoutineMode"

    var scheduleMode: ScheduleMode {
        get { userDefaults.string(forKey: Self.scheduleModeKey).flatMap(ScheduleMode.init(rawValue:)) ?? .fixedWeek }
        set {
            userDefaults.set(newValue.rawValue, forKey: Self.scheduleModeKey)
            objectWillChange.send()
            publishSummary()
        }
    }

    /// Las sesiones con ejercicios, en orden de semana (A, B, C…).
    var sessionOrder: [WorkoutDay] {
        WorkoutDay.allCases.sorted { $0.weekOrder < $1.weekOrder }.filter { !(dailyWorkoutRecords[$0] ?? []).isEmpty }
    }

    func slotLetter(_ day: WorkoutDay) -> String? {
        guard let i = sessionOrder.firstIndex(of: day), i < 26 else { return nil }
        return String(UnicodeScalar(UInt8(65 + i)))
    }

    /// "Lunes" o, en secuencia, "Sesión A".
    func slotName(_ day: WorkoutDay) -> String {
        if scheduleMode == .sequence, let l = slotLetter(day) { return String(localized: "Sesión \(l)") }
        return day.displayName
    }

    /// "Lun" o, en secuencia, "A".
    func slotShort(_ day: WorkoutDay) -> String {
        if scheduleMode == .sequence, let l = slotLetter(day) { return l }
        return day.shortLabel
    }

    /// Nombre completo para avisos, widget y Siri: "Lunes · Pierna", "Sesión B · Torso".
    func sessionTitle(_ day: WorkoutDay) -> String {
        label(for: day).map { "\(slotName(day)) · \($0)" } ?? slotName(day)
    }

    func weekInterval(containing date: Date) -> DateInterval? {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal.dateInterval(of: .weekOfYear, for: date)
    }

    // MARK: - Qué se ha hecho

    /// La sesión con series en esa fecha (la de hoy aún no está en el historial).
    func slotDone(on date: Date) -> WorkoutDay? {
        let cal = Calendar.current
        let d = cal.startOfDay(for: date)
        if d == sessionDate {
            let marked = WorkoutDay.allCases.compactMap { day -> (WorkoutDay, Date)? in
                let recs = dailyWorkoutRecords[day] ?? []
                guard recs.contains(where: { $0.completedSets > 0 }) else { return nil }
                return (day, recs.compactMap(\.lastSetCompletedAt).max() ?? d)
            }
            if let last = marked.max(by: { $0.1 < $1.1 }) { return last.0 }
        }
        guard let byDay = workoutHistory[d] else { return nil }
        return byDay.filter { $0.value.contains { $0.completedSets > 0 } }
            .max { ($0.value.compactMap(\.lastSetCompletedAt).max() ?? d) < ($1.value.compactMap(\.lastSetCompletedAt).max() ?? d) }?.key
    }

    /// La última sesión hecha antes de esa fecha.
    func lastSlotDone(before date: Date) -> WorkoutDay? {
        let cal = Calendar.current
        let limit = cal.startOfDay(for: date)
        for d in workoutHistory.keys.filter({ $0 < limit }).sorted(by: >) {
            if let s = slotDone(on: d) { return s }
        }
        return nil
    }

    /// Sesiones hechas en la semana (lunes a domingo) de esa fecha, hasta ese día incluido.
    func slotsDoneThisWeek(upTo date: Date) -> Set<WorkoutDay> {
        let cal = Calendar.current
        guard let week = weekInterval(containing: date) else { return [] }
        var done = Set<WorkoutDay>()
        var d = week.start
        let end = cal.startOfDay(for: date)
        while d <= end {
            if let s = slotDone(on: d) { done.insert(s) }
            guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        return done
    }

    /// Semana flexible: lo que tocaba hasta hoy y no se ha hecho, en orden.
    func pendingThisWeek(on date: Date = Date()) -> [WorkoutDay] {
        guard let today = WorkoutDay.from(date: date) else { return [] }
        let done = slotsDoneThisWeek(upTo: date)
        return sessionOrder.filter { $0.weekOrder <= today.weekOrder && !done.contains($0) }
    }

    // MARK: - El motor

    /// La sesión que toca en esa fecha; nil = descanso.
    func nextSession(on date: Date = Date()) -> WorkoutDay? {
        if let inProgress = slotDone(on: date) { return inProgress }
        let weekday = WorkoutDay.from(date: date) ?? .monday
        switch scheduleMode {
        case .fixedWeek:
            return (dailyWorkoutRecords[weekday] ?? []).isEmpty ? nil : weekday
        case .elasticWeek:
            if isPostponed(on: date) { return nil }
            return pendingThisWeek(on: date).first
        case .sequence:
            let order = sessionOrder
            guard !order.isEmpty else { return nil }
            guard let last = lastSlotDone(before: date), let i = order.firstIndex(of: last) else { return order.first }
            return order[(i + 1) % order.count]
        }
    }

    /// Lo que enseña Inicio al abrir: la que toca o, si toca descanso, el hueco
    /// de hoy (semana fija) o la siguiente que se podría adelantar.
    var todaySession: WorkoutDay {
        if let s = nextSession() { return s }
        let weekday = WorkoutDay.from(date: Date()) ?? .monday
        if scheduleMode == .elasticWeek {
            let done = slotsDoneThisWeek(upTo: Date())
            if let ahead = sessionOrder.first(where: { !done.contains($0) }) { return ahead }
        }
        return weekday
    }

    /// Una línea bajo el título de Inicio que explica por qué toca esa sesión.
    func sessionHint(for day: WorkoutDay, now: Date = Date()) -> String? {
        guard !(dailyWorkoutRecords[day] ?? []).isEmpty else { return nil }
        let weekday = WorkoutDay.from(date: now) ?? .monday
        switch scheduleMode {
        case .fixedWeek:
            return nil
        case .elasticWeek:
            if isPostponed(on: now), day == todaySession { return "Hoy no puedes: queda pendiente para otro día de la semana." }
            if slotsDoneThisWeek(upTo: now).contains(day), slotDone(on: now) != day { return "Ya la hiciste esta semana." }
            if day.weekOrder < weekday.weekOrder, pendingThisWeek(on: now).contains(day) { return "Pendiente desde el \(day.displayName.lowercased())." }
            if day.weekOrder > weekday.weekOrder { return String(localized: "Vas al día: puedes adelantar la del \(day.displayName.lowercased()).") }
            return nil
        case .sequence:
            guard day == nextSession(on: now) else { return nil }
            if let last = lastSlotDone(before: now), slotDone(on: now) == nil { return String(localized: "Toca después de \(slotName(last)).") }
            return nil
        }
    }

    // MARK: - «Hoy no puedo» (semana flexible)

    func isPostponed(on date: Date = Date()) -> Bool {
        guard let d = userDefaults.object(forKey: "PostponedOn") as? Date else { return false }
        return Calendar.current.isDate(d, inSameDayAs: date)
    }

    func postponeToday(_ on: Bool = true) {
        if on { userDefaults.set(Calendar.current.startOfDay(for: Date()), forKey: "PostponedOn") }
        else { userDefaults.removeObject(forKey: "PostponedOn") }
        objectWillChange.send()
        publishSummary()
        Reminders.reschedule(for: self)
    }

    /// Cambia el modo de la rutina activa.
    func setScheduleMode(_ mode: ScheduleMode) {
        scheduleMode = mode
        trainingDay = todaySession
        PhoneConnectivity.shared.sendTodayContext()
        Reminders.reschedule(for: self)
        SystemCalendar.sync(self)
    }
}
