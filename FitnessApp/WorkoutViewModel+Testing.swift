//
//  WorkoutViewModel+Testing.swift
//  ChamaFit
//
//  Siembra de datos para la batería de pruebas de UI. Solo actúa cuando la
//  app arranca en modo prueba (dominio de datos aparte): en uso normal no
//  hace nada.
//
//    --seed-sample    rutina de ejemplo (3 días, 13 ejercicios)
//    --seed-history   además, dos semanas de historial con series, peso y notas
//

import Foundation

extension WorkoutViewModel {

    func seedForUITestsIfRequested() {
        guard AppDefaults.isTesting, availableExercises.isEmpty else { return }
        if AppDefaults.has("--seed-sample") || AppDefaults.has("--seed-history") {
            loadSampleRoutine()
        }
        if AppDefaults.has("--seed-history") { seedHistory() }
    }

    /// Catorce días de historial (los días con rutina), con pesos crecientes
    /// para que haya récords, gráficas con tendencia y comparación semanal.
    func seedHistory() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for back in 1...14 {
            guard let date = cal.date(byAdding: .day, value: -back, to: today),
                  let day = WorkoutDay.from(date: date) else { continue }
            let template = dailyWorkoutRecords[day] ?? []
            guard !template.isEmpty else { continue }
            var records: [WorkoutExercise] = []
            for (i, rec) in template.enumerated() {
                guard let ex = getExercise(by: rec.exerciseId) else { continue }
                var r = rec.resettingProgress()
                // Los ejercicios impares quedan a medias en los días antiguos.
                let done = (back > 7 && i % 2 == 1) ? max(1, ex.totalSets - 1) : ex.totalSets
                let base = ex.weight > 0 ? ex.weight + Double(14 - back) * 1.25 : 0
                for s in 0..<done {
                    var log = SetLog(reps: ex.repetitions, weight: base, type: s == 0 && base > 0 ? .warmup : .normal,
                                     rpe: s == done - 1 ? 8 : nil)
                    log.date = date.addingTimeInterval(TimeInterval(10 * 60 + s * 180))
                    r.setLogs.append(log)
                }
                r.completedSets = done
                r.lastSetCompletedAt = r.setLogs.last?.date
                records.append(r)
            }
            workoutHistory[date] = [day: records]
            bodyWeightHistory[date] = 80 - Double(14 - back) * 0.1
            if back % 4 == 0 { sessionNotes[date] = "Buena sesión, sin molestias." }
        }
        saveNow()
        publishSummary()
    }
}
