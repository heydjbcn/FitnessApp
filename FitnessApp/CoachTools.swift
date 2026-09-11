//
//  CoachTools.swift
//  ChamaFit
//
//  Lo que el coach puede consultar (historial, estadísticas de un ejercicio,
//  notas, constancia) y proponer (sustituir, series y repeticiones, añadir,
//  quitar, descanso, reordenar). Las propuestas nunca se aplican solas: se
//  enseñan con Aplicar / Descartar y, tras aplicar, se pueden deshacer.
//

import Foundation
import Combine

enum CoachChange: Codable, Equatable {
    case substitute(day: WorkoutDay?, from: String, to: String)
    case setsReps(exercise: String, sets: Int?, reps: Int?)
    case add(day: WorkoutDay, exercise: String, sets: Int, reps: Int)
    case remove(day: WorkoutDay?, exercise: String)
    case rest(exercise: String, seconds: Int)
    case reorder(day: WorkoutDay, order: [String])

    var text: String {
        switch self {
        case .substitute(let d, let from, let to): return String(localized: "Cambiar \(from) por \(to)\(d.map { " el \($0.displayName.lowercased())" } ?? " en toda la rutina")")
        case .setsReps(let e, let s, let r):
            return "\(e): " + [s.map { String(localized: "\($0) series") }, r.map { String(localized: "\($0) repeticiones") }].compactMap { $0 }.joined(separator: " de ")
        case .add(let d, let e, let s, let r): return String(localized: "Añadir \(e) el \(d.displayName.lowercased()) · \(s) × \(r)")
        case .remove(let d, let e): return String(localized: "Quitar \(e)\(d.map { " del \($0.displayName.lowercased())" } ?? " de la rutina")")
        case .rest(let e, let s): return String(localized: "\(e): descanso de \(WorkoutViewModel.restText(s))")
        case .reorder(let d, let order): return String(localized: "Reordenar el \(d.displayName.lowercased()): ") + order.joined(separator: " → ")
        }
    }
}

struct CoachProposal: Identifiable, Equatable {
    let id = UUID()
    var reason: String
    var changes: [CoachChange]
}

extension WorkoutViewModel {

    // MARK: - Consultas (texto para el modelo)

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX"); return f
    }()

    func findExercise(_ name: String) -> Exercise? {
        let key = ExerciseLibrary.fold(name)
        return availableExercises.first { ExerciseLibrary.fold($0.name) == key }
            ?? availableExercises.first { ExerciseLibrary.fold($0.name).contains(key) || key.contains(ExerciseLibrary.fold($0.name)) }
    }

    /// Sesiones entre dos fechas (yyyy-MM-dd), con lo hecho en cada una.
    func toolHistory(from: String, to: String) -> String {
        let cal = Calendar.current
        let start = Self.dayFormatter.date(from: from).map(cal.startOfDay) ?? cal.date(byAdding: .day, value: -14, to: Date())!
        let end = Self.dayFormatter.date(from: to) ?? Date()
        let dates = workoutHistory.keys.filter { $0 >= start && $0 <= end }.sorted()
        guard !dates.isEmpty else { return String(localized: "No hay sesiones entre \(from) y \(to).") }
        var lines: [String] = []
        for d in dates.suffix(40) {
            guard let byDay = workoutHistory[d] else { continue }
            for (slot, recs) in byDay {
                let done = recs.filter { $0.completedSets > 0 }
                guard !done.isEmpty else { continue }
                let items = done.compactMap { r -> String? in
                    guard let ex = getExercise(by: r.exerciseId) else { return nil }
                    let best = r.setLogs.max { $0.weight < $1.weight }
                    let w = best.map { $0.weight > 0 ? " \(WorkoutViewModel.weightText($0.weight, kind: ex.loadKind)) × \($0.reps)" : " × \($0.reps)" } ?? ""
                    return String(localized: "\(ex.name) \(r.completedSets) series\(w)")
                }
                let note = sessionNotes[d].map { String(localized: " · nota: \($0)") } ?? ""
                lines.append("\(Self.dayFormatter.string(from: d)) (\(slotName(slot))): " + items.joined(separator: "; ") + note)
            }
        }
        return lines.joined(separator: "\n")
    }

    /// Récord, 1RM estimado y últimas sesiones de un ejercicio.
    func toolExerciseStats(_ name: String) -> String {
        guard let ex = findExercise(name) else { return String(localized: "No tengo ningún ejercicio que se llame \(name). Los que hay: \(availableExercises.map(\.name).joined(separator: ", ")).") }
        var out = [String(localized: "\(ex.name): plantilla \(meta(for: ex)), descanso \(WorkoutViewModel.restText(ex.restDuration)).")]
        if let pr = personalRecord(for: ex.id) {
            out.append(String(localized: "Récord: \(WorkoutViewModel.weightText(pr.weight, kind: ex.loadKind))") + (pr.oneRepMax > 0 ? ", 1RM estimado \(WorkoutViewModel.kg((pr.oneRepMax * 10).rounded() / 10))." : "."))
        }
        let sessions = pastWorkSessions(for: ex.id).prefix(6)
        for s in sessions {
            guard let first = s.first else { continue }
            let sets = s.map { "\(Units.number($0.weight))×\($0.reps)\($0.rpe.map { "@\($0)" } ?? "")" }.joined(separator: ", ")
            out.append("\(Self.dayFormatter.string(from: first.date)): \(sets)")
        }
        if let sug = suggestion(for: ex) { out.append(String(localized: "Sugerencia de hoy: \(sug.text) (\(sug.reason))")) }
        return out.joined(separator: "\n")
    }

    /// Busca en notas de sesión, ajustes de máquina y descripciones.
    func toolSearchNotes(_ query: String) -> String {
        let q = ExerciseLibrary.fold(query)
        guard !q.isEmpty else { return "Dime qué buscar." }
        var hits: [String] = []
        for (d, note) in sessionNotes.sorted(by: { $0.key > $1.key }) where ExerciseLibrary.fold(note).contains(q) {
            hits.append(String(localized: "Nota del \(Self.dayFormatter.string(from: d)): \(note)"))
        }
        for ex in availableExercises {
            if let s = ex.setupText, ExerciseLibrary.fold(s).contains(q) || ExerciseLibrary.fold(ex.name).contains(q) {
                hits.append(String(localized: "Ajuste de máquina de \(ex.name): \(s)"))
            }
            if !ex.info.isEmpty, ExerciseLibrary.fold(ex.info).contains(q) { hits.append("Descripción de \(ex.name): \(ex.info)") }
        }
        return hits.isEmpty ? "No encuentro «\(query)» en tus notas." : hits.prefix(20).joined(separator: "\n")
    }

    /// Constancia de las últimas 8 semanas y qué días fallan.
    func toolConsistency(now: Date = Date()) -> String {
        var lines: [String] = []
        for offset in stride(from: -7, through: 0, by: 1) {
            let w = weekStats(offset: offset)
            let start = weekInterval(offset: offset).start
            lines.append(String(localized: "Semana del \(Self.dayFormatter.string(from: start)): \(w.sessions) de \(weeklySessionGoal) sesiones, \(w.sets) series"))
        }
        // Días de la semana con sesión prevista que se saltaron (semana fija).
        var missed: [WorkoutDay: Int] = [:]
        var hours: [Int] = []
        let cal = Calendar.current
        for back in 1...56 {
            guard let d = cal.date(byAdding: .day, value: -back, to: cal.startOfDay(for: now)), let wd = WorkoutDay.from(date: d) else { continue }
            if hasWorkoutForDate(d) {
                if let first = workoutHistory[d]?.values.flatMap({ $0 }).flatMap(\.setLogs).map(\.date).min() {
                    hours.append(cal.component(.hour, from: first))
                }
            } else if scheduleMode == .fixedWeek, !(dailyWorkoutRecords[wd] ?? []).isEmpty {
                missed[wd, default: 0] += 1
            }
        }
        if !missed.isEmpty {
            lines.append("Días previstos sin entrenar (8 semanas): " + missed.sorted { $0.value > $1.value }.map { "\($0.key.displayName) \($0.value)" }.joined(separator: ", "))
        }
        if !hours.isEmpty {
            let morning = hours.filter { $0 < 14 }.count
            lines.append(String(localized: "Entrenas \(morning) veces por la mañana y \(hours.count - morning) por la tarde."))
        }
        lines.append(String(localized: "Racha actual: \(consecutiveWorkoutDays()) días. Modo de la rutina: \(scheduleMode.label)."))
        return lines.joined(separator: "\n")
    }

    // MARK: - Proponer (valida) y aplicar

    /// Comprueba que los nombres existen; devuelve la propuesta y lo que no cuadra.
    func validate(_ changes: [CoachChange]) -> (ok: [CoachChange], problems: [String]) {
        var ok: [CoachChange] = [], problems: [String] = []
        func known(_ n: String) -> Bool { findExercise(n) != nil }
        func exists(_ n: String) -> Bool { known(n) || ExerciseCatalog.entry(named: n) != nil }
        for c in changes {
            switch c {
            case .substitute(_, let from, let to):
                if !known(from) { problems.append(String(localized: "No tienes \(from) en la rutina.")) } else if !exists(to) { problems.append(String(localized: "\(to) no está en la biblioteca.")) } else { ok.append(c) }
            case .setsReps(let e, let s, let r):
                if !known(e) { problems.append(String(localized: "No encuentro \(e).")) }
                else if (s.map { !(1...12).contains($0) } ?? false) || (r.map { !(1...100).contains($0) } ?? false) { problems.append("Cifras raras para \(e).") }
                else { ok.append(c) }
            case .add(_, let e, let s, let r):
                if !exists(e) { problems.append(String(localized: "\(e) no está en la biblioteca.")) } else if !(1...12).contains(s) || !(1...100).contains(r) { problems.append("Cifras raras para \(e).") } else { ok.append(c) }
            case .remove(_, let e), .rest(let e, _):
                if known(e) { ok.append(c) } else { problems.append(String(localized: "No encuentro \(e).")) }
            case .reorder(_, let order):
                if order.allSatisfy(known) { ok.append(c) } else { problems.append("Hay ejercicios que no conozco en el orden propuesto.") }
            }
        }
        return (ok, problems)
    }

    /// Aplica y devuelve la copia de antes (para deshacer).
    @discardableResult
    func apply(_ proposal: CoachProposal) -> Data? {
        let snapshot = try? backupData()
        for c in proposal.changes { apply(c) }
        persistAll()
        publishSummary()
        PhoneConnectivity.shared.sendTodayContext()
        HapticManager.shared.success()
        return snapshot
    }

    private func exerciseNamed(_ n: String) -> Exercise? {
        findExercise(n) ?? ExerciseCatalog.entry(named: n).map(exerciseFromCatalog)
    }

    private func apply(_ c: CoachChange) {
        switch c {
        case .substitute(let day, let from, let to):
            guard let old = findExercise(from), let new = exerciseNamed(to) else { return }
            for d in day.map({ [$0] }) ?? WorkoutDay.allCases {
                for r in (dailyWorkoutRecords[d] ?? []) where r.exerciseId == old.id {
                    substitute(recordId: r.id, in: d, with: new, forever: true)
                }
            }
        case .setsReps(let e, let s, let r):
            guard var ex = findExercise(e) else { return }
            if let s { ex.totalSets = s }
            if let r, ex.segundos == 0 { ex.repetitions = r }
            updateBaseExercise(ex)
        case .add(let day, let e, let s, let r):
            guard var ex = exerciseNamed(e) else { return }
            if ex.totalSets != s || (ex.segundos == 0 && ex.repetitions != r) {
                ex.totalSets = s
                if ex.segundos == 0 { ex.repetitions = r }
                updateBaseExercise(ex)
            }
            if !(dailyWorkoutRecords[day] ?? []).contains(where: { $0.exerciseId == ex.id }) {
                dailyWorkoutRecords[day, default: []].append(WorkoutExercise(exerciseId: ex.id))
            }
        case .remove(let day, let e):
            guard let ex = findExercise(e) else { return }
            for d in day.map({ [$0] }) ?? WorkoutDay.allCases {
                for r in (dailyWorkoutRecords[d] ?? []) where r.exerciseId == ex.id { removeExercise(recordId: r.id, from: d) }
            }
        case .rest(let e, let s):
            guard var ex = findExercise(e) else { return }
            ex.restDuration = min(600, max(0, s))
            updateBaseExercise(ex)
        case .reorder(let day, let order):
            guard var recs = dailyWorkoutRecords[day] else { return }
            let ids = order.compactMap { findExercise($0)?.id }
            recs.sort { a, b in (ids.firstIndex(of: a.exerciseId) ?? 99) < (ids.firstIndex(of: b.exerciseId) ?? 99) }
            dailyWorkoutRecords[day] = recs
        }
    }

    /// Vuelve a como estaba antes de aplicar.
    func undoCoach(_ snapshot: Data) {
        try? restore(from: snapshot, mode: .replace)
    }

    // MARK: - Texto → plan

    /// Crea la rutina desde una leída de un texto: acepta ejercicios que no
    /// están en el catálogo (se crean con lo que diga el texto).
    @discardableResult
    func applyParsedRoutine(_ g: GeneratedRoutine, named name: String) -> Int {
        let clean = name.trimmingCharacters(in: .whitespaces)
        createRoutine(named: clean.isEmpty ? g.name : clean, copyingCurrent: false)
        var added = 0
        var used = Set<WorkoutDay>()
        for d in g.days {
            guard let day = WorkoutDay(rawValue: d.day), !used.contains(day) else { continue }
            used.insert(day)
            if !d.label.trimmingCharacters(in: .whitespaces).isEmpty { setLabel(d.label, for: day) }
            for item in d.exercises {
                let name = item.name.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { continue }
                let ex: Exercise
                if let mine = findExercise(name), ExerciseLibrary.fold(mine.name) == ExerciseLibrary.fold(name) {
                    ex = mine
                } else if let c = ExerciseCatalog.entry(named: name) {
                    ex = exerciseFromCatalog(c)
                } else {
                    let new = Exercise(name: name, repetitions: max(1, item.reps), weight: 0, totalSets: min(12, max(1, item.sets)),
                                       restDuration: min(600, max(0, item.restSeconds)), sfSymbolIcon: "dumbbell.fill", iconColor: "accent")
                    availableExercises.append(new)
                    ex = new
                }
                if !(dailyWorkoutRecords[day] ?? []).contains(where: { $0.exerciseId == ex.id }) {
                    dailyWorkoutRecords[day, default: []].append(WorkoutExercise(exerciseId: ex.id))
                    added += 1
                }
            }
        }
        activeDays = WorkoutDay.allCases.filter { !(dailyWorkoutRecords[$0] ?? []).isEmpty }
        persistAll()
        publishSummary()
        return added
    }
}

/// Lo que el coach ha propuesto en la conversación en curso (lo rellenan las herramientas).
@MainActor
final class CoachProposals: ObservableObject {
    static let shared = CoachProposals()
    @Published var latest: CoachProposal? = nil

    /// Traduce la lista genérica de cambios que devuelve el modelo.
    static func parse(_ items: [[String: Any]]) -> [CoachChange] {
        items.compactMap { i in
            let kind = (i["kind"] as? String ?? "").lowercased()
            let day = (i["day"] as? String).flatMap { d in WorkoutDay.allCases.first { ExerciseLibrary.fold($0.rawValue) == ExerciseLibrary.fold(d) } }
            let ex = i["exercise"] as? String ?? ""
            let sets = (i["sets"] as? NSNumber)?.intValue
            let reps = (i["reps"] as? NSNumber)?.intValue
            switch kind {
            case "substitute", "sustituir":
                guard let to = i["new_exercise"] as? String ?? i["newExercise"] as? String else { return nil }
                return .substitute(day: day, from: ex, to: to)
            case "sets_reps", "series":
                return .setsReps(exercise: ex, sets: sets, reps: reps)
            case "add", "anadir", "añadir":
                guard let day else { return nil }
                return .add(day: day, exercise: ex, sets: sets ?? 3, reps: reps ?? 10)
            case "remove", "quitar":
                return .remove(day: day, exercise: ex)
            case "rest", "descanso":
                guard let s = (i["seconds"] as? NSNumber)?.intValue else { return nil }
                return .rest(exercise: ex, seconds: s)
            case "reorder", "reordenar":
                guard let day, let order = i["order"] as? [String] else { return nil }
                return .reorder(day: day, order: order)
            default:
                return nil
            }
        }
    }
}
