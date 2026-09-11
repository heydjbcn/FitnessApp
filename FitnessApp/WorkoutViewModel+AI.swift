//
//  WorkoutViewModel+AI.swift
//  ChamaFit
//
//  Convertir una rutina propuesta por la IA en una rutina de verdad, y el
//  contexto (compacto) que se le pasa al coach.
//

import Foundation

extension WorkoutViewModel {

    /// Crea la rutina propuesta como rutina nueva y la activa (la actual queda
    /// guardada en Calendario › Rutinas). Reutiliza los ejercicios que ya
    /// existan con el mismo nombre y crea el resto desde el catálogo.
    /// Devuelve cuántos ejercicios ha añadido al plan.
    @discardableResult
    func applyGeneratedRoutine(_ g: GeneratedRoutine, named name: String) -> Int {
        let clean = name.trimmingCharacters(in: .whitespaces)
        createRoutine(named: clean.isEmpty ? g.name : clean, copyingCurrent: false)
        var added = 0
        var usedDays = Set<WorkoutDay>()
        for d in g.days {
            guard let day = WorkoutDay(rawValue: d.day), !usedDays.contains(day) else { continue }
            usedDays.insert(day)
            let label = d.label.trimmingCharacters(in: .whitespaces)
            if !label.isEmpty { setLabel(label, for: day) }
            for item in d.exercises {
                guard let exercise = exerciseForGenerated(item) else { continue }
                if (dailyWorkoutRecords[day] ?? []).contains(where: { $0.exerciseId == exercise.id }) { continue }
                dailyWorkoutRecords[day, default: []].append(WorkoutExercise(exerciseId: exercise.id))
                added += 1
            }
        }
        activeDays = WorkoutDay.allCases.filter { !(dailyWorkoutRecords[$0] ?? []).isEmpty }
        persistAll()
        publishSummary()
        return added
    }

    private func exerciseForGenerated(_ item: GeneratedRoutine.Item) -> Exercise? {
        if let existing = availableExercises.first(where: { $0.name.caseInsensitiveCompare(item.name) == .orderedSame
                                                            || $0.name.caseInsensitiveCompare(item.name.loc) == .orderedSame }) {
            return existing
        }
        guard let c = ExerciseCatalog.all.first(where: { $0.name.caseInsensitiveCompare(item.name) == .orderedSame }) else { return nil }
        let timed = c.reps == 0
        let ex = Exercise(name: c.name.loc, repetitions: timed ? 0 : max(1, item.reps), weight: c.weight,
                          totalSets: min(12, max(1, item.sets)),
                          restDuration: min(600, max(0, item.restSeconds)), sfSymbolIcon: c.icon, iconColor: "accent",
                          segundos: timed ? max(5, item.reps) : 0, muscleGroup: c.muscleGroup)
        availableExercises.append(ex)
        return ex
    }

    /// Resumen para el coach: rutina, marcas, semana y recuperación. `compact`
    /// para el modelo del iPhone, que tiene poco contexto.
    func coachContext(compact: Bool = false, recovery: Recovery? = nil) -> String {
        var lines: [String] = []
        if trainingProfile.completed {
            lines.append("PERFIL: \(trainingProfile.summary); material: \(activeEquipment.name) (\(activeEquipment.summary)).")
        }
        lines.append("RUTINA SEMANAL (\(scheduleMode.label.lowercased()); hoy toca \(nextSession().map(sessionTitle) ?? "descanso")):")
        for day in WorkoutDay.allCases.sorted(by: { $0.weekOrder < $1.weekOrder }) {
            let recs = dailyWorkoutRecords[day] ?? []
            guard !recs.isEmpty else { continue }
            let label = self.label(for: day).map { " (\($0))" } ?? ""
            lines.append("\(slotName(day))\(label):")
            for r in recs {
                guard let ex = getExercise(by: r.exerciseId) else { continue }
                var line = "  - \(ex.name): \(meta(for: ex))"
                if !compact {
                    if let g = ex.muscleGroup { line += " [\(g)]" }
                    line += ", descanso \(WorkoutViewModel.restText(ex.restDuration))"
                }
                if ex.loadKind != .total { line += " (\(ex.loadKind.label.lowercased()))" }
                if let pr = personalRecord(for: ex.id), pr.weight > 0 { line += ", récord \(WorkoutViewModel.weightText(pr.weight, kind: ex.loadKind))" }
                if !compact, let last = lastPerformance(for: ex.id) {
                    line += ", última serie \(WorkoutViewModel.weightText(last.weight, kind: ex.loadKind)) × \(last.reps)"
                }
                lines.append(line)
            }
        }
        if lines.last?.hasPrefix("RUTINA SEMANAL") == true { lines.append("(sin ejercicios todavía)") }
        if let prog = activeProgram, let w = programWeek() {
            lines.append("PROGRAMA: \(prog.name), semana \(w.index + 1) de \(prog.weeks.count) (\(w.week.label)).")
        }
        let w = weekStats(), prev = weekStats(offset: -1)
        lines.append("ESTA SEMANA: \(w.sessions) de \(weeklySessionGoal) sesiones objetivo, \(w.sets) series, \(Units.tonnage(w.volume)). Semana anterior: \(prev.sessions) sesiones, \(prev.sets) series, \(Units.tonnage(prev.volume)).")
        if Units.weight == .lb { lines.append("El usuario usa libras: da los pesos en lb.") }
        let groups = setsByMuscleGroup().map { "\($0.group) \($0.sets)" }.joined(separator: ", ")
        if !groups.isEmpty { lines.append("Series por grupo esta semana: \(groups).") }
        lines.append("Racha: \(consecutiveWorkoutDays()) días.")
        if let r = recovery, r.hasSignals {
            var h = "RECUPERACIÓN HOY: \(r.headline)."
            if let s = r.sleepHours { h += " Sueño \(String(format: "%.1f", s)) h." }
            if let hr = r.restingHR, let a = r.restingHRAvg { h += " Pulso en reposo \(Int(hr)) (media \(Int(a)))." }
            lines.append(h)
        }
        return lines.joined(separator: "\n")
    }
}
