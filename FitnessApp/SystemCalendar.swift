//
//  SystemCalendar.swift
//  ChamaFit
//
//  Calendario «ChamaFit» en la app Calendario del iPhone: las próximas dos
//  semanas de sesiones (a la hora del recordatorio, con su duración
//  estimada) y, si se quiere, las hechas con su resumen. Se rehace entero
//  cada vez que cambia la rutina o se vuelve del fondo.
//

import Foundation
import EventKit

struct CalendarSession: Equatable {
    let date: Date
    let slot: WorkoutDay
    let title: String
    let minutes: Int
}

extension WorkoutViewModel {

    /// Duración estimada de una sesión entera (con tus tiempos reales).
    func estimatedSessionMinutes(_ day: WorkoutDay) -> Int {
        let recs = dailyWorkoutRecords[day] ?? []
        let seconds = recs.reduce(0.0) { total, r in
            guard let ex = getExercise(by: r.exerciseId) else { return total }
            let sets = Double(ex.totalSets)
            return total + sets * secondsPerSet(ex) - min(Double(ex.restDuration), secondsPerSet(ex) * 0.5) + 60
        }
        return max(10, Int((seconds / 60).rounded()))
    }

    /// Qué sesiones caen en los próximos días según el modo de la rutina.
    /// En secuencia, se reparten por los días de la semana que tienen sesión.
    func calendarPlan(from now: Date = Date(), days: Int = 14) -> [CalendarSession] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        let order = sessionOrder
        guard !order.isEmpty else { return [] }
        var out: [CalendarSession] = []
        var nextIndex = nextSession(on: now).flatMap { order.firstIndex(of: $0) } ?? 0
        for offset in 0..<days {
            guard let day = cal.date(byAdding: .day, value: offset, to: start), let wd = WorkoutDay.from(date: day) else { continue }
            // Hoy, si ya entrenaste, no se propone.
            if offset == 0 && hasWorkoutForDate(day) {
                if scheduleMode == .sequence, let done = slotDone(on: day), let i = order.firstIndex(of: done) { nextIndex = (i + 1) % order.count }
                continue
            }
            let slot: WorkoutDay
            switch scheduleMode {
            case .fixedWeek, .elasticWeek:
                guard order.contains(wd) else { continue }
                slot = wd
            case .sequence:
                guard order.contains(wd) else { continue }   // los días habituales de entreno
                slot = order[nextIndex % order.count]
                nextIndex += 1
            }
            out.append(CalendarSession(date: day, slot: slot, title: sessionTitle(slot), minutes: estimatedSessionMinutes(slot)))
        }
        return out
    }
}

@MainActor
enum SystemCalendar {
    private static let store = EKEventStore()
    private static var defaults: UserDefaults { AppDefaults.store }

    static var enabled: Bool {
        get { defaults.bool(forKey: "CalendarSync") }
        set { defaults.set(newValue, forKey: "CalendarSync") }
    }

    /// También las sesiones hechas, con su resumen.
    static var logDone: Bool {
        get { defaults.object(forKey: "CalendarLogDone") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "CalendarLogDone") }
    }

    static func requestAccess() async -> Bool {
        (try? await store.requestFullAccessToEvents()) ?? false
    }

    static var authorized: Bool { EKEventStore.authorizationStatus(for: .event) == .fullAccess }

    /// El calendario «ChamaFit» (lo crea si no existe).
    private static func calendar() -> EKCalendar? {
        if let id = defaults.string(forKey: "CalendarId"), let c = store.calendar(withIdentifier: id) { return c }
        let c = EKCalendar(for: .event, eventStore: store)
        c.title = "ChamaFit"
        c.cgColor = CGColor(red: 0.95, green: 0.33, blue: 0.45, alpha: 1)
        c.source = store.defaultCalendarForNewEvents?.source
            ?? store.sources.first { $0.sourceType == .calDAV } ?? store.sources.first { $0.sourceType == .local }
        do {
            try store.saveCalendar(c, commit: true)
            defaults.set(c.calendarIdentifier, forKey: "CalendarId")
            return c
        } catch { return nil }
    }

    /// Rehace las próximas dos semanas y apunta lo hecho hoy.
    static func sync(_ vm: WorkoutViewModel, now: Date = Date()) {
        guard !AppDefaults.isTesting, enabled, authorized, let cal = calendar() else { return }
        let horizon = now.addingTimeInterval(15 * 86_400)
        let start = Calendar.current.startOfDay(for: now)
        // Fuera lo planificado (nunca lo ya hecho: esos llevan «✓»).
        let old = store.events(matching: store.predicateForEvents(withStart: start, end: horizon, calendars: [cal]))
        for e in old where !(e.title ?? "").hasPrefix("✓") { try? store.remove(e, span: .thisEvent, commit: false) }
        let minutes = Reminders.minutes
        for s in vm.calendarPlan(from: now) {
            let e = EKEvent(eventStore: store)
            e.calendar = cal
            e.title = "🏋️ \(s.title)"
            e.startDate = s.date.addingTimeInterval(TimeInterval(minutes * 60))
            e.endDate = e.startDate.addingTimeInterval(TimeInterval(s.minutes * 60))
            let n = (vm.dailyWorkoutRecords[s.slot] ?? []).compactMap { vm.getExercise(by: $0.exerciseId)?.name }
            e.notes = n.joined(separator: " · ")
            e.url = URL(string: "chamafit://entreno")
            try? store.save(e, span: .thisEvent, commit: false)
        }
        if logDone, vm.hasWorkoutForDate(now), let slot = vm.slotDone(on: now),
           let bounds = vm.sessionBounds(for: slot) {
            let key = "CalendarDone-\(Calendar.current.startOfDay(for: now).timeIntervalSince1970)"
            let summary = String(localized: "\(vm.completedSets(for: slot)) series · \(Units.tonnage(vm.volume(for: slot)))")
            if let id = defaults.string(forKey: key), let e = store.event(withIdentifier: id) {
                e.endDate = max(bounds.end, bounds.start.addingTimeInterval(600))
                e.notes = summary
                try? store.save(e, span: .thisEvent, commit: false)
            } else {
                let e = EKEvent(eventStore: store)
                e.calendar = cal
                e.title = "✓ \(vm.sessionTitle(slot))"
                e.startDate = bounds.start
                e.endDate = max(bounds.end, bounds.start.addingTimeInterval(600))
                e.notes = summary
                if (try? store.save(e, span: .thisEvent, commit: false)) != nil { defaults.set(e.eventIdentifier, forKey: key) }
            }
        }
        try? store.commit()
    }

    /// Quita el calendario «ChamaFit» entero.
    static func removeAll() {
        guard authorized, let id = defaults.string(forKey: "CalendarId"), let c = store.calendar(withIdentifier: id) else { return }
        try? store.removeCalendar(c, commit: true)
        defaults.removeObject(forKey: "CalendarId")
    }
}
