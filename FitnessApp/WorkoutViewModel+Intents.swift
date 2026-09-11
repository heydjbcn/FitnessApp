//
//  WorkoutViewModel+Intents.swift
//  ChamaFit
//
//  Lo que hacen las acciones de Siri, Atajos, el Botón de Acción y los
//  Controles. Devuelven la frase que Siri dice (o enseña) al terminar.
//

import Foundation
import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif

extension WorkoutViewModel {

    /// El día que se está entrenando de verdad: si hoy ya hay series marcadas
    /// en algún día de rutina, ese (el de la última serie); si no, el de Inicio.
    var activeTrainingDay: WorkoutDay {
        let marked = WorkoutDay.allCases.compactMap { day -> (WorkoutDay, Date)? in
            let last = (dailyWorkoutRecords[day] ?? []).compactMap(\.lastSetCompletedAt).max()
            return last.map { (day, $0) }
        }
        return marked.max { $0.1 < $1.1 }?.0 ?? nextSession() ?? trainingDay
    }

    func handle(_ action: AppAction) -> String {
        ensureSession()
        let day = activeTrainingDay
        switch action {
        case .markSet, .logSet:
            guard let rec = nextRecord(in: day), let ex = getExercise(by: rec.exerciseId) else {
                return (dailyWorkoutRecords[day] ?? []).isEmpty
                    ? "Hoy no tienes ejercicios en la rutina."
                    : "¡Ya has hecho todas las series de hoy!"
            }
            if case .logSet(let w, let r) = action {
                completeSet(for: rec.id, in: day, weight: Units.toKg(max(0, w)), reps: max(1, r))
            } else {
                completeSet(for: rec.id, in: day)
            }
            let updated = dailyWorkoutRecords[day]?.first { $0.id == rec.id }
            let n = updated?.completedSets ?? rec.completedSets + 1
            var text = String(localized: "Serie \(n) de \(updated.map { $0.planned(ex) } ?? ex.totalSets) de \(ex.name)")
            if let log = updated?.setLogs.last {
                text += ex.segundos > 0 ? ": \(log.reps) segundos." :
                    log.weight > 0 ? ": \(Units.number(log.weight)) \(WorkoutViewModel.unitWord) por \(log.reps)." : String(localized: ": \(log.reps) repeticiones.")
            } else { text += "." }
            if timerActive { text += String(localized: " Descanso de \(WorkoutViewModel.restText(currentTimerDuration)).") }
            return text

        case .undoSet:
            let recs = dailyWorkoutRecords[day] ?? []
            guard let last = recs.filter({ $0.completedSets > 0 })
                    .max(by: { ($0.lastSetCompletedAt ?? .distantPast) < ($1.lastSetCompletedAt ?? .distantPast) }),
                  let ex = getExercise(by: last.exerciseId) else { return "No hay ninguna serie que deshacer." }
            undoLastSet(for: last.id, in: day)
            return String(localized: "Quitada la serie \(last.completedSets) de \(ex.name).")

        case .startRest:
            let rest = nextRecord(in: day).flatMap { getExercise(by: $0.exerciseId)?.restDuration } ?? defaultRestDuration
            let duration = rest > 0 ? rest : defaultRestDuration
            timerLabel = "Descanso"
            startTimer(duration: duration)
            return String(localized: "Descanso de \(WorkoutViewModel.restText(duration)).")

        case .extendRest:
            guard timerActive else { return "No hay ningún descanso en marcha." }
            extendTimer(by: 30)
            return String(localized: "Treinta segundos más. Quedan \(WorkoutViewModel.restText(timeRemaining)).")

        case .stopRest:
            guard timerActive else { return "No había ningún descanso en marcha." }
            stopTimer()
            return "Descanso terminado."

        case .today:
            let recs = dailyWorkoutRecords[day] ?? []
            guard !recs.isEmpty, nextSession() != nil || completedSets(for: day) > 0 else {
                if scheduleMode == .elasticWeek, let ahead = sessionOrder.first(where: { !slotsDoneThisWeek(upTo: Date()).contains($0) }) {
                    return String(localized: "Hoy no te toca nada: vas al día. Si te apetece, puedes adelantar \(sessionTitle(ahead)).")
                }
                return "Hoy es día libre. ¡A descansar!"
            }
            let name = label(for: day).map { "\(slotName(day)), \($0)" } ?? slotName(day)
            let n = recs.count, sets = totalSets(for: day)
            var text = String(localized: "Hoy toca \(name): \(n == 1 ? String(localized: "1 ejercicio") : String(localized: "\(n) ejercicios")) y \(sets == 1 ? String(localized: "1 serie") : String(localized: "\(sets) series")).")
            let done = completedSets(for: day)
            if done > 0 { text += String(localized: " Llevas \(done).") }
            if let next = nextUpText(in: day) { text += String(localized: " Siguiente: \(next).") } else if done > 0 { text += " ¡Sesión completada!" }
            return text

        case .openWorkout:
            pendingWorkoutOpen = true
            return "Abriendo el modo entreno."

        case .logWeight(let value):
            // Siri da el número en la unidad elegida en la app.
            let kg = Units.toKg(value)
            updateBodyWeight(for: Date(), weight: kg)
            return String(localized: "Apuntado: \(WorkoutViewModel.kg(kg)).")
        }
    }

    /// El descanso en el App Group, para que el Control del Centro de control
    /// sepa si está en marcha.
    func syncRestState() {
        guard !AppDefaults.isTesting else { return }
        SharedRestState.end = timerActive ? timerEndDate : nil
        #if canImport(WidgetKit)
        ControlCenter.shared.reloadControls(ofKind: "Mauri.FitnessApp.rest")
        #endif
    }
}
