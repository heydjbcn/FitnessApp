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
        return marked.max { $0.1 < $1.1 }?.0 ?? trainingDay
    }

    func handle(_ action: AppAction) -> String {
        ensureSession()
        let day = activeTrainingDay
        switch action {
        case .markSet:
            guard let rec = nextRecord(in: day), let ex = getExercise(by: rec.exerciseId) else {
                return (dailyWorkoutRecords[day] ?? []).isEmpty
                    ? "Hoy no tienes ejercicios en la rutina."
                    : "¡Ya has hecho todas las series de hoy!"
            }
            completeSet(for: rec.id, in: day)
            let updated = dailyWorkoutRecords[day]?.first { $0.id == rec.id }
            let n = updated?.completedSets ?? rec.completedSets + 1
            var text = "Serie \(n) de \(ex.totalSets) de \(ex.name)"
            if let log = updated?.setLogs.last {
                text += ex.segundos > 0 ? ": \(log.reps) segundos." :
                    log.weight > 0 ? ": \(WorkoutViewModel.number(log.weight)) kilos por \(log.reps)." : ": \(log.reps) repeticiones."
            } else { text += "." }
            if timerActive { text += " Descanso de \(WorkoutViewModel.restText(currentTimerDuration))." }
            return text

        case .undoSet:
            let recs = dailyWorkoutRecords[day] ?? []
            guard let last = recs.filter({ $0.completedSets > 0 })
                    .max(by: { ($0.lastSetCompletedAt ?? .distantPast) < ($1.lastSetCompletedAt ?? .distantPast) }),
                  let ex = getExercise(by: last.exerciseId) else { return "No hay ninguna serie que deshacer." }
            undoLastSet(for: last.id, in: day)
            return "Quitada la serie \(last.completedSets) de \(ex.name)."

        case .startRest:
            let rest = nextRecord(in: day).flatMap { getExercise(by: $0.exerciseId)?.restDuration } ?? defaultRestDuration
            let duration = rest > 0 ? rest : defaultRestDuration
            timerLabel = "Descanso"
            startTimer(duration: duration)
            return "Descanso de \(WorkoutViewModel.restText(duration))."

        case .extendRest:
            guard timerActive else { return "No hay ningún descanso en marcha." }
            extendTimer(by: 30)
            return "Treinta segundos más. Quedan \(WorkoutViewModel.restText(timeRemaining))."

        case .stopRest:
            guard timerActive else { return "No había ningún descanso en marcha." }
            stopTimer()
            return "Descanso terminado."

        case .today:
            let recs = dailyWorkoutRecords[day] ?? []
            guard !recs.isEmpty else { return "Hoy es día libre. ¡A descansar!" }
            let name = label(for: day).map { "\(day.displayName), \($0)" } ?? day.displayName
            let n = recs.count, sets = totalSets(for: day)
            var text = "Hoy toca \(name): \(n == 1 ? "1 ejercicio" : "\(n) ejercicios") y \(sets == 1 ? "1 serie" : "\(sets) series")."
            let done = completedSets(for: day)
            if done > 0 { text += " Llevas \(done)." }
            if let next = nextUpText(in: day) { text += " Siguiente: \(next)." } else if done > 0 { text += " ¡Sesión completada!" }
            return text

        case .openWorkout:
            pendingWorkoutOpen = true
            return "Abriendo el modo entreno."

        case .logWeight(let kg):
            updateBodyWeight(for: Date(), weight: kg)
            return "Apuntado: \(WorkoutViewModel.kg(kg))."
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
