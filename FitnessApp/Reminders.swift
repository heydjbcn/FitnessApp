//
//  Reminders.swift
//  ChamaFit
//
//  Recordatorio de entreno a tu hora los días con rutina (los próximos 7,
//  saltando los ya entrenados) y resumen de la semana los lunes a las 9:00.
//  Se reprograma cada vez que la app se va al fondo, con las cifras al día.
//

import Foundation
import SwiftUI
import UserNotifications

enum Reminders {
    static var enabled: Bool {
        get { AppDefaults.store.bool(forKey: "reminderEnabled") }
        set { AppDefaults.store.set(newValue, forKey: "reminderEnabled") }
    }
    static var weeklyEnabled: Bool {
        get { AppDefaults.store.object(forKey: "weeklySummaryEnabled") as? Bool ?? true }
        set { AppDefaults.store.set(newValue, forKey: "weeklySummaryEnabled") }
    }
    /// Minutos desde medianoche (por defecto, 18:00).
    static var minutes: Int {
        get { AppDefaults.store.object(forKey: "reminderMinutes") as? Int ?? 18 * 60 }
        set { AppDefaults.store.set(newValue, forKey: "reminderMinutes") }
    }

    struct Planned: Equatable { let id: String; let date: Date; let title: String; let body: String }

    /// Qué avisos tocan desde `now` (sin tocar el sistema: se prueba solo).
    @MainActor
    static func plan(for vm: WorkoutViewModel, now: Date = Date()) -> [Planned] {
        let cal = Calendar.current
        var out: [Planned] = []
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"

        if enabled {
            func planned(_ wd: WorkoutDay, on day: Date, fire: Date) -> Planned {
                let recs = vm.dailyWorkoutRecords[wd] ?? []
                let sets = recs.reduce(0) { $0 + (vm.getExercise(by: $1.exerciseId)?.totalSets ?? 0) }
                return Planned(id: "reminder-\(f.string(from: day))", date: fire, title: String(localized: "Hoy toca \(vm.sessionTitle(wd))"),
                               body: String(localized: "\(recs.count) ejercicios · \(sets) series. ¡A por ello!"))
            }
            switch vm.scheduleMode {
            case .fixedWeek, .elasticWeek:
                let doneThisWeek = vm.slotsDoneThisWeek(upTo: now)
                for offset in 0..<7 {
                    guard let day = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: now)),
                          let wd = WorkoutDay.from(date: day) else { continue }
                    guard !(vm.dailyWorkoutRecords[wd] ?? []).isEmpty else { continue }
                    let fire = day.addingTimeInterval(TimeInterval(minutes * 60))
                    guard fire > now else { continue }
                    if offset == 0 && vm.hasWorkoutForDate(day) { continue }   // hoy ya entrenaste
                    if vm.scheduleMode == .elasticWeek {
                        // Flexible: lo ya hecho esta semana no se recuerda y «hoy no puedo» calla el de hoy.
                        if offset == 0 && vm.isPostponed(on: now) { continue }
                        if doneThisWeek.contains(wd) && cal.isDate(day, equalTo: now, toGranularity: .weekOfYear) { continue }
                    }
                    out.append(planned(wd, on: day, fire: fire))
                }
            case .sequence:
                // Sin días: un solo aviso, el próximo día sin entrenar, con la sesión que toca.
                for offset in 0..<2 {
                    guard let day = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: now)) else { continue }
                    let fire = day.addingTimeInterval(TimeInterval(minutes * 60))
                    guard fire > now, !vm.hasWorkoutForDate(day), let wd = vm.nextSession(on: day) else { continue }
                    out.append(planned(wd, on: day, fire: fire))
                    break
                }
            }
        }

        if weeklyEnabled {
            var comps = DateComponents(); comps.weekday = 2; comps.hour = 9; comps.minute = 0
            if let monday = cal.nextDate(after: now, matching: comps, matchingPolicy: .nextTime) {
                // Las cifras de la semana que acaba antes de ese lunes.
                let offset = cal.isDate(monday, equalTo: now, toGranularity: .weekOfYear) ? -1 : 0
                let s = vm.weekStats(offset: offset)
                let prev = vm.weekStats(offset: offset - 1)
                var body = String(localized: "\(s.sessions) \((s.sessions == 1 ? "sesión" : "sesiones").loc) · \(s.sets) series · \(WorkoutViewModel.tonnageText(s.volume))")
                if prev.volume > 0 {
                    let pct = Int(((s.volume - prev.volume) / prev.volume * 100).rounded())
                    body += String(localized: " (\(pct >= 0 ? "+" : "")\(pct) % frente a la anterior)")
                }
                if s.sessions == 0 { body = "Semana sin entrenos. Esta es buena para volver." }
                out.append(Planned(id: "weekly-\(f.string(from: monday))", date: monday, title: "Tu semana en ChamaFit", body: body))
            }
        }
        return out
    }

    @MainActor
    static func reschedule(for vm: WorkoutViewModel) {
        guard !AppDefaults.isTesting, vm.notificationsEnabled else { return }
        let center = UNUserNotificationCenter.current()
        let planned = plan(for: vm)
        Task {
            let pending = await center.pendingNotificationRequests()
            let old = pending.map(\.identifier).filter { $0.hasPrefix("reminder-") || $0.hasPrefix("weekly-") }
            center.removePendingNotificationRequests(withIdentifiers: old)
            guard !planned.isEmpty else { return }
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            for p in planned {
                let content = UNMutableNotificationContent()
                content.title = p.title
                content.body = p.body
                content.sound = .default
                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: p.date)
                try? await center.add(UNNotificationRequest(identifier: p.id, content: content,
                                                            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
            }
        }
    }

    /// Activar los recordatorios pide permiso si hace falta.
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let s = await center.notificationSettings()
        if s.authorizationStatus == .notDetermined {
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
        return s.authorizationStatus == .authorized
    }
}

/// Ajustes de los avisos programados, en la hoja de Notificaciones.
struct RemindersCard: View {
    let p: Palette
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var enabled = Reminders.enabled
    @State private var weekly = Reminders.weeklyEnabled
    @State private var time = Calendar.current.startOfDay(for: Date()).addingTimeInterval(TimeInterval(Reminders.minutes * 60))

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                IconTile(symbol: "alarm.fill", p: p)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recordatorio de entreno").font(.fig(14, .semibold)).foregroundColor(p.ink)
                    Text("Los días con rutina, si aún no has entrenado").font(.fig(11, .medium)).foregroundColor(p.mute)
                }
                Spacer(minLength: 4)
                PulsoToggle(isOn: $enabled, p: p).accessibilityIdentifier("toggle.Recordatorio")
            }
            if enabled {
                DatePicker("Hora", selection: $time, displayedComponents: .hourAndMinute)
                    .font(.fig(13, .semibold)).foregroundColor(p.ink)
                    .tint(p.acc)
            }
            HStack(spacing: 12) {
                IconTile(symbol: "chart.bar.fill", p: p)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Resumen del lunes").font(.fig(14, .semibold)).foregroundColor(p.ink)
                    Text("Tu semana en una notificación, a las 9:00").font(.fig(11, .medium)).foregroundColor(p.mute)
                }
                Spacer(minLength: 4)
                PulsoToggle(isOn: $weekly, p: p).accessibilityIdentifier("toggle.Resumen")
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
        .onChange(of: enabled) { _, on in
            Reminders.enabled = on
            if on { Task { _ = await Reminders.requestPermission(); Reminders.reschedule(for: viewModel) } }
            else { Reminders.reschedule(for: viewModel) }
        }
        .onChange(of: weekly) { _, on in Reminders.weeklyEnabled = on; Reminders.reschedule(for: viewModel) }
        .onChange(of: time) { _, t in
            let c = Calendar.current.dateComponents([.hour, .minute], from: t)
            Reminders.minutes = (c.hour ?? 18) * 60 + (c.minute ?? 0)
            Reminders.reschedule(for: viewModel)
        }
    }
}
