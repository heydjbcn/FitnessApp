//
//  WorkoutViewModel+HistoryEdit.swift
//  ChamaFit
//
//  Corregir series de sesiones pasadas: cambiar peso, reps, tipo o RPE,
//  borrar una serie o añadir una que se olvidó marcar. Si la fecha es la
//  de la sesión en curso, se toca la sesión de hoy (que se refleja sola en
//  el historial). Récords, gráficas y CSV se recalculan solos.
//

import Foundation

/// Un ejercicio hecho en una fecha concreta.
struct HistoryRef: Hashable, Identifiable {
    let date: Date
    let day: WorkoutDay
    let recordId: UUID
    var id: String { "\(date.timeIntervalSince1970)-\(recordId)" }
}

extension WorkoutViewModel {

    /// El registro de un ejercicio en una fecha (el que más series tenga si hay varios).
    func historyRef(for exerciseId: UUID, on date: Date) -> HistoryRef? {
        let key = Calendar.current.startOfDay(for: date)
        guard let byDay = workoutHistory[key] else { return nil }
        let found = byDay.flatMap { day, recs in recs.filter { $0.exerciseId == exerciseId }.map { (day, $0) } }
            .max { $0.1.completedSets < $1.1.completedSets }
        return found.map { HistoryRef(date: key, day: $0.0, recordId: $0.1.id) }
    }

    func historyRecord(_ ref: HistoryRef) -> WorkoutExercise? {
        if isCurrentSession(ref.date) { return dailyWorkoutRecords[ref.day]?.first { $0.id == ref.recordId } }
        return workoutHistory[ref.date]?[ref.day]?.first { $0.id == ref.recordId }
    }

    private func isCurrentSession(_ date: Date) -> Bool {
        Calendar.current.startOfDay(for: date) == sessionDate
    }

    func updatePastSet(_ log: SetLog, _ ref: HistoryRef) {
        if isCurrentSession(ref.date) { updateSetLog(log, for: ref.recordId, in: ref.day); return }
        editHistory(ref) { rec in
            guard let i = rec.setLogs.firstIndex(where: { $0.id == log.id }) else { return }
            rec.setLogs[i] = log
        }
    }

    func deletePastSet(_ logId: UUID, _ ref: HistoryRef) {
        if isCurrentSession(ref.date) { deleteSetLog(logId, for: ref.recordId, in: ref.day); return }
        editHistory(ref) { rec in rec.setLogs.removeAll { $0.id == logId } }
        HapticManager.shared.warning()
    }

    /// Una serie que se olvidó marcar ese día (a continuación de la última).
    func addPastSet(_ ref: HistoryRef, weight: Double, reps: Int, type: SetType = .normal) {
        if isCurrentSession(ref.date) {
            completeSet(for: ref.recordId, in: ref.day, weight: weight, reps: reps, type: type)
            return
        }
        editHistory(ref) { rec in
            let after = rec.setLogs.last?.date ?? ref.date.addingTimeInterval(18 * 3600)
            rec.setLogs.append(SetLog(reps: reps, weight: weight, type: type, date: after.addingTimeInterval(180)))
        }
    }

    private func editHistory(_ ref: HistoryRef, _ change: (inout WorkoutExercise) -> Void) {
        guard var byDay = workoutHistory[ref.date], var recs = byDay[ref.day],
              let i = recs.firstIndex(where: { $0.id == ref.recordId }) else { return }
        var rec = recs[i]
        change(&rec)
        rec.completedSets = rec.setLogs.count
        rec.lastSetCompletedAt = rec.setLogs.last?.date
        recs[i] = rec
        byDay[ref.day] = recs
        // Sin ninguna serie ese día, el día deja de contar como entrenado.
        if byDay.values.allSatisfy({ $0.allSatisfy { $0.completedSets == 0 } }) {
            workoutHistory.removeValue(forKey: ref.date)
        } else {
            workoutHistory[ref.date] = byDay
        }
        persistAll()
    }
}
