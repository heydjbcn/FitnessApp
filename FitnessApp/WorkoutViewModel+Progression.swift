//
//  WorkoutViewModel+Progression.swift
//  ChamaFit
//
//  Sobrecarga progresiva sin IA: qué peso toca hoy según cómo fue la última
//  sesión del ejercicio. Solo mira series de trabajo (normales y al fallo).
//

import Foundation

struct WeightSuggestion: Equatable {
    enum Trend { case up, same, down }
    let weight: Double
    let reps: Int
    let trend: Trend
    /// Una frase: "La última vez: 4 × 8 con 60 kg y RPE 8. Toca subir."
    let reason: String
    var kind: LoadKind = .total

    /// "62,5 kg × 8"
    var text: String {
        weight > 0 || kind == .assisted ? "\(WorkoutViewModel.weightText(weight, kind: kind)) × \(reps)" : String(localized: "\(reps) reps")
    }

    var arrow: String {
        switch trend { case .up: return "arrow.up"; case .same: return "equal"; case .down: return "arrow.down" }
    }
}

extension WorkoutViewModel {

    /// Series de trabajo de un ejercicio agrupadas por día, de la más reciente
    /// a la más antigua. Sin la sesión de hoy: la sugerencia es para hoy.
    func pastWorkSessions(for exerciseId: UUID) -> [[SetLog]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let work = allSetLogs(for: exerciseId).filter { $0.type == .normal || $0.type == .failure }
        let byDay = Dictionary(grouping: work) { cal.startOfDay(for: $0.date) }
        // Las sesiones ligeras («hoy me cuesta») no cuentan para decidir.
        return byDay.filter { $0.key < today && !isLightDay($0.key) }
            .sorted { $0.key > $1.key }
            .map { $0.value.sorted { $0.date < $1.date } }
    }

    /// Peso y reps para hoy. nil si nunca se ha hecho o es por tiempo.
    /// Con la recuperación en rojo no sube; en ámbar, solo si la última vez fue fácil (RPE ≤ 7).
    func suggestion(for exercise: Exercise) -> WeightSuggestion? {
        suggestion(for: exercise, recovery: HealthManager.shared.isAvailable ? HealthManager.shared.recovery.level : nil)
    }

    func suggestion(for exercise: Exercise, recovery: Recovery.Level?) -> WeightSuggestion? {
        var s = adjustedSuggestion(for: exercise, recovery: recovery)
        // «Hoy me cuesta»: 90 % de lo de la última vez, sin subir.
        if isLightToday, let base = s, base.weight > 0, !exercise.loadKind.lowerIsBetter {
            let step = Units.weight == .kg ? 1.25 : 2.5
            let light = Units.toKg((Units.fromKg(lastTopWeight(exercise) * 0.9) / step).rounded() * step)
            var l = WeightSuggestion(weight: light, reps: base.reps, trend: .down,
                                     reason: "Día ligero: 90 % del peso y una serie menos. Hoy cuenta venir.")
            l.kind = exercise.loadKind
            return l
        }
        // Programa: la descarga manda sobre todo lo demás; si no, se recuerda el RPE de la semana.
        if let w = programWeek(), inProgram(exercise.id), let base = s {
            if w.week.deload && base.weight > 0 && !exercise.loadKind.lowerIsBetter {
                let step = Units.weight == .kg ? 1.25 : 2.5
                let light = Units.toKg((Units.fromKg(lastTopWeight(exercise) * w.week.load) / step).rounded() * step)
                s = WeightSuggestion(weight: light, reps: base.reps, trend: .down,
                                     reason: String(localized: "Semana de descarga del programa: \(Int(w.week.load * 100)) % del peso y una serie menos."))
            } else if let rpe = w.week.rpe {
                s = WeightSuggestion(weight: base.weight, reps: base.reps, trend: base.trend,
                                     reason: base.reason + String(localized: " Objetivo de la semana: RPE \(rpe)."))
            }
        }
        s?.kind = exercise.loadKind
        return s
    }

    private func adjustedSuggestion(for exercise: Exercise, recovery: Recovery.Level?) -> WeightSuggestion? {
        guard let base = baseSuggestion(for: exercise), base.trend == .up else { return baseSuggestion(for: exercise) }
        let lastRPE = pastWorkSessions(for: exercise.id).first?.compactMap(\.rpe).max()
        let holdWeight = base.weight > 0 || exercise.loadKind.lowerIsBetter ? lastTopWeight(exercise) : 0
        let holdReps = base.weight > 0 ? base.reps : max(1, base.reps - 1)
        switch recovery {
        case .easy:
            return WeightSuggestion(weight: holdWeight, reps: holdReps, trend: .same,
                                    reason: "Recuperación baja hoy (sueño o pulsaciones): mantén lo de la última vez.")
        case .normal where (lastRPE ?? 10) > 7:
            return WeightSuggestion(weight: holdWeight, reps: holdReps, trend: .same,
                                    reason: "Día normal según tu recuperación: sube solo cuando la última vez fuera fácil (RPE 7 o menos).")
        default:
            return base
        }
    }

    func lastTopWeight(_ exercise: Exercise) -> Double {
        pastWorkSessions(for: exercise.id).first.flatMap { Self.best($0.map(\.weight), kind: exercise.loadKind) } ?? exercise.weight
    }

    private func baseSuggestion(for exercise: Exercise) -> WeightSuggestion? {
        guard exercise.segundos == 0 else { return nil }
        let sessions = pastWorkSessions(for: exercise.id)
        guard let last = sessions.first, !last.isEmpty else { return nil }

        // La serie «de arriba» es la más exigente: la de más peso o, si es
        // asistido, la de menos ayuda.
        let kind = exercise.loadKind
        let top = Self.best(last.map(\.weight), kind: kind) ?? 0
        let atTop = last.filter { $0.weight == top }
        let target = exercise.repetitions > 0 ? exercise.repetitions : (atTop.map(\.reps).max() ?? 0)
        guard target > 0 else { return nil }

        let hit = atTop.allSatisfy { $0.reps >= target }
        let missed = atTop.contains { $0.reps <= target - 2 }
        let maxRPE = atTop.compactMap(\.rpe).max()
        let wentToFailure = atTop.contains { $0.type == .failure } || (maxRPE ?? 0) >= 10
        let rpeText = maxRPE.map { String(localized: " y RPE \($0)") } ?? ""
        let setsText = "\(atTop.count) × \(atTop.map(\.reps).min() ?? target)"

        // Asistido: progresar es quitar ayuda.
        if kind.lowerIsBetter && top > 0 {
            let dec = Units.toKg(Units.weight == .kg ? 2.5 : 5)
            if hit && !wentToFailure && (maxRPE ?? 8) <= 8 {
                return WeightSuggestion(weight: max(0, top - dec), reps: target, trend: .up,
                                        reason: String(localized: "La última vez: \(setsText) con \(WorkoutViewModel.kg(top)) de ayuda\(rpeText). Quita un poco de asistencia."))
            }
            if missed {
                return WeightSuggestion(weight: top + dec, reps: target, trend: .down,
                                        reason: String(localized: "Te faltaron repeticiones con \(WorkoutViewModel.kg(top)) de ayuda. Pon un poco más y vuelve a bajarla."))
            }
            return WeightSuggestion(weight: top, reps: target, trend: .same,
                                    reason: String(localized: "Repite con \(WorkoutViewModel.kg(top)) de ayuda hasta que salga cómodo."))
        }

        // Peso corporal: se progresa en repeticiones.
        if top == 0 {
            if hit && !wentToFailure {
                return WeightSuggestion(weight: 0, reps: target + 1, trend: .up,
                                        reason: String(localized: "Completaste \(setsText). Prueba una repetición más."))
            }
            return WeightSuggestion(weight: 0, reps: target, trend: .same,
                                    reason: String(localized: "Repite hasta completar las \(target) repeticiones."))
        }

        if hit && !wentToFailure && (maxRPE ?? 8) <= 8 {
            // 1 kg / 2,5 kg; en libras 2,5 lb / 5 lb.
            let inc = Units.weight == .kg ? (top < 20 ? 1.0 : 2.5) : Units.toKg(Units.fromKg(top) < 45 ? 2.5 : 5)
            return WeightSuggestion(weight: top + inc, reps: target, trend: .up,
                                    reason: String(localized: "La última vez: \(setsText) con \(WorkoutViewModel.kg(top))\(rpeText). Toca subir."))
        }

        if missed, sessions.count > 1 {
            let previous = sessions[1]
            let prevTop = previous.map(\.weight).max() ?? 0
            let prevMissed = previous.filter { $0.weight == prevTop }.contains { $0.reps <= target - 2 }
            if prevTop == top && prevMissed {
                let fine = Units.weight == .kg ? 1.25 : 2.5
                let lower = max(0, Units.toKg((Units.fromKg(top * 0.95) / fine).rounded(.down) * fine))
                return WeightSuggestion(weight: lower, reps: target, trend: .down,
                                        reason: String(localized: "Dos sesiones sin llegar a \(target) con \(WorkoutViewModel.kg(top)). Baja un poco y vuelve a subir."))
            }
        }

        let why = hit ? "Completaste, pero exigente\(rpeText)." : "Te faltaron repeticiones la última vez."
        return WeightSuggestion(weight: top, reps: target, trend: .same,
                                reason: String(localized: "\(why) Repite \(WorkoutViewModel.kg(top)) hasta que salga cómodo."))
    }

    /// La serie con la que arranca el editor rápido o el modo entreno: la
    /// sugerencia si la hay; si no, lo último hecho; si no, la plantilla.
    func proposedSet(for exercise: Exercise, record: WorkoutExercise?) -> (weight: Double, reps: Int) {
        // Dentro de la sesión manda la serie anterior de hoy.
        if let today = record?.setLogs.last(where: { $0.type == .normal || $0.type == .failure }) {
            return (today.weight, today.reps)
        }
        if let s = suggestion(for: exercise) { return (s.weight, s.reps) }
        if let last = lastPerformance(for: exercise.id) { return (last.weight, last.reps) }
        return (exercise.weight, exercise.repetitions)
    }
}
