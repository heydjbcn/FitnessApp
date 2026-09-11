//
//  Program.swift
//  ChamaFit
//
//  Programas de varias semanas: una rutina de base más un plan semana a
//  semana (series, repeticiones, RPE objetivo y semanas de descarga). Al
//  cambiar de semana, las series y repeticiones de los ejercicios del
//  programa se ajustan solas; al terminar vuelven a como estaban.
//

import Foundation
import Combine

struct ProgramWeek: Codable, Equatable {
    var label: String
    /// Series de más (o de menos) en los ejercicios principales.
    var setsDelta: Int = 0
    /// Repeticiones de más (o de menos) en los principales.
    var repsDelta: Int = 0
    var rpe: Int? = nil
    /// Factor sobre el peso de trabajo: 0,9 en descarga.
    var load: Double = 1
    var note: String = ""
    var deload: Bool { load < 1 }
}

struct ProgramItem: Equatable {
    let name: String
    let sets: Int
    let reps: Int
    var rest: Int = 90
    /// Principal: se le aplica la progresión de la semana. Los accesorios solo la descarga.
    var main = false
}

struct ProgramTemplate: Identifiable, Equatable {
    let id: String
    let name: String
    let summary: String
    let level: TrainingProfile.Level
    let goals: [TrainingProfile.Goal]
    let mode: ScheduleMode
    let sessionsPerWeek: Int
    /// Sesiones: nombre y ejercicios. En semana fija, `days` dice qué día va cada una.
    let sessions: [(label: String, items: [ProgramItem])]
    var days: [WorkoutDay] = []
    let weeks: [ProgramWeek]

    static func == (a: ProgramTemplate, b: ProgramTemplate) -> Bool { a.id == b.id }

    /// Todo el material que piden sus ejercicios.
    var needs: Set<Equipment> {
        sessions.flatMap(\.items).reduce(into: Set<Equipment>()) { $0.formUnion(ExerciseLibrary.details(for: $1.name)?.needs ?? []) }
    }

    func fits(_ equipment: EquipmentProfile) -> Bool { needs.isSubset(of: equipment.items) }

    /// Los huecos donde van las sesiones.
    var slots: [WorkoutDay] {
        if !days.isEmpty { return days }
        let order = WorkoutDay.allCases.sorted { $0.weekOrder < $1.weekOrder }
        // Flexible con 3 sesiones: lunes, miércoles y viernes; secuencia: seguidas.
        if mode == .elasticWeek && sessions.count == 3 { return [.monday, .wednesday, .friday] }
        return Array(order.prefix(sessions.count))
    }
}

struct ActiveProgram: Codable, Equatable {
    struct Target: Codable, Equatable { var sets: Int; var reps: Int; var main: Bool }

    var templateId: String
    var name: String
    var routineName: String
    var start: Date
    var weeks: [ProgramWeek]
    var sessionsPerWeek: Int
    /// Avanza por sesiones hechas (si faltas una semana, no pierdes la progresión).
    var bySessions = true
    /// Series y repeticiones de partida de cada ejercicio del programa.
    var base: [UUID: Target] = [:]
    /// Cómo estaban esos ejercicios antes de empezar (se devuelven al terminar).
    var original: [UUID: Target] = [:]
    var appliedWeek = -1
}

enum ProgramTemplates {

    /// Progresión estándar: tres semanas subiendo y una de descarga.
    static func blocks(_ count: Int, rpes: [Int] = [7, 8, 8], deloadEvery: Int = 4) -> [ProgramWeek] {
        (0..<count).map { i in
            let n = i + 1
            if n % deloadEvery == 0 {
                return ProgramWeek(label: String(localized: "Semana \(n) · descarga"), setsDelta: -1, load: 0.9,
                                   note: "Descarga: 90 % del peso y una serie menos. Recuperas y vuelves más fuerte.")
            }
            let block = i / deloadEvery
            let inBlock = i % deloadEvery
            return ProgramWeek(label: String(localized: "Semana \(n)"), setsDelta: inBlock >= 2 ? 1 : 0, repsDelta: -2 * block,
                               rpe: rpes[min(inBlock, rpes.count - 1)] + (block > 0 ? 1 : 0),
                               note: inBlock == 0 ? "Empieza cómodo: deja 3 repeticiones en la recámara." :
                                     inBlock == 1 ? "Sube un poco: 2 repeticiones en la recámara." :
                                     "Una serie más en los principales. Aprieta.")
        }
    }

    static let all: [ProgramTemplate] = [
        ProgramTemplate(
            id: "fullbody3", name: "Full body 3 días",
            summary: "Todo el cuerpo en cada sesión, alternando A y B. Ideal para empezar o volver.",
            level: .beginner, goals: [.hypertrophy, .strength, .health], mode: .sequence, sessionsPerWeek: 3,
            sessions: [
                ("Full body A", [ProgramItem(name: "Sentadilla", sets: 3, reps: 10, rest: 120, main: true),
                                 ProgramItem(name: "Press de banca", sets: 3, reps: 10, rest: 120, main: true),
                                 ProgramItem(name: "Remo con barra", sets: 3, reps: 10, main: true),
                                 ProgramItem(name: "Curl femoral", sets: 3, reps: 12),
                                 ProgramItem(name: "Plancha", sets: 3, reps: 0, rest: 60)]),
                ("Full body B", [ProgramItem(name: "Peso muerto rumano", sets: 3, reps: 10, rest: 120, main: true),
                                 ProgramItem(name: "Press militar", sets: 3, reps: 10, rest: 120, main: true),
                                 ProgramItem(name: "Jalón al pecho", sets: 3, reps: 10, main: true),
                                 ProgramItem(name: "Zancadas", sets: 3, reps: 10),
                                 ProgramItem(name: "Elevaciones laterales", sets: 3, reps: 15, rest: 60)]),
            ],
            weeks: blocks(8)),
        ProgramTemplate(
            id: "upperlower4", name: "Torso / pierna 4 días",
            summary: "Dos de torso y dos de pierna por semana. Más volumen para ganar músculo.",
            level: .intermediate, goals: [.hypertrophy, .strength], mode: .fixedWeek, sessionsPerWeek: 4,
            sessions: [
                ("Torso A", [ProgramItem(name: "Press de banca", sets: 4, reps: 8, rest: 150, main: true),
                             ProgramItem(name: "Remo con barra", sets: 4, reps: 8, rest: 120, main: true),
                             ProgramItem(name: "Press de hombros con mancuernas", sets: 3, reps: 10),
                             ProgramItem(name: "Jalón al pecho", sets: 3, reps: 10),
                             ProgramItem(name: "Curl con mancuernas", sets: 3, reps: 12, rest: 60),
                             ProgramItem(name: "Extensiones en polea", sets: 3, reps: 12, rest: 60)]),
                ("Pierna A", [ProgramItem(name: "Sentadilla", sets: 4, reps: 8, rest: 180, main: true),
                              ProgramItem(name: "Peso muerto rumano", sets: 3, reps: 10, rest: 120, main: true),
                              ProgramItem(name: "Prensa", sets: 3, reps: 12),
                              ProgramItem(name: "Curl femoral", sets: 3, reps: 12),
                              ProgramItem(name: "Gemelos de pie", sets: 4, reps: 15, rest: 60)]),
                ("Torso B", [ProgramItem(name: "Press militar", sets: 4, reps: 8, rest: 150, main: true),
                             ProgramItem(name: "Dominadas", sets: 4, reps: 8, rest: 120, main: true),
                             ProgramItem(name: "Press inclinado mancuernas", sets: 3, reps: 10),
                             ProgramItem(name: "Remo con mancuerna", sets: 3, reps: 10),
                             ProgramItem(name: "Face pull", sets: 3, reps: 15, rest: 60),
                             ProgramItem(name: "Curl martillo", sets: 3, reps: 12, rest: 60)]),
                ("Pierna B", [ProgramItem(name: "Peso muerto", sets: 3, reps: 6, rest: 180, main: true),
                              ProgramItem(name: "Sentadilla búlgara", sets: 3, reps: 10),
                              ProgramItem(name: "Hip thrust", sets: 3, reps: 10),
                              ProgramItem(name: "Extensión de cuádriceps", sets: 3, reps: 15, rest: 60),
                              ProgramItem(name: "Rueda abdominal", sets: 3, reps: 10, rest: 60)]),
            ],
            days: [.monday, .tuesday, .thursday, .friday],
            weeks: blocks(8)),
        ProgramTemplate(
            id: "ppl6", name: "Empuje / tirón / pierna",
            summary: "Tres sesiones que se repiten en orden, sin días fijos. Hazlas 3 o 6 veces por semana.",
            level: .advanced, goals: [.hypertrophy], mode: .sequence, sessionsPerWeek: 6,
            sessions: [
                ("Empuje", [ProgramItem(name: "Press de banca", sets: 4, reps: 8, rest: 150, main: true),
                            ProgramItem(name: "Press inclinado mancuernas", sets: 3, reps: 10),
                            ProgramItem(name: "Press militar", sets: 3, reps: 8, rest: 120, main: true),
                            ProgramItem(name: "Elevaciones laterales", sets: 4, reps: 15, rest: 60),
                            ProgramItem(name: "Extensiones en polea", sets: 3, reps: 12, rest: 60),
                            ProgramItem(name: "Cruce de poleas", sets: 3, reps: 15, rest: 60)]),
                ("Tirón", [ProgramItem(name: "Peso muerto", sets: 3, reps: 6, rest: 180, main: true),
                           ProgramItem(name: "Dominadas", sets: 4, reps: 8, rest: 120, main: true),
                           ProgramItem(name: "Remo con barra", sets: 3, reps: 10),
                           ProgramItem(name: "Face pull", sets: 3, reps: 15, rest: 60),
                           ProgramItem(name: "Curl con barra", sets: 3, reps: 10, rest: 60),
                           ProgramItem(name: "Curl martillo", sets: 3, reps: 12, rest: 60)]),
                ("Pierna", [ProgramItem(name: "Sentadilla", sets: 4, reps: 8, rest: 180, main: true),
                            ProgramItem(name: "Prensa", sets: 3, reps: 12),
                            ProgramItem(name: "Peso muerto rumano", sets: 3, reps: 10, rest: 120, main: true),
                            ProgramItem(name: "Curl femoral", sets: 3, reps: 12),
                            ProgramItem(name: "Gemelos de pie", sets: 4, reps: 15, rest: 60),
                            ProgramItem(name: "Elevación de piernas", sets: 3, reps: 15, rest: 60)]),
            ],
            weeks: blocks(8)),
        ProgramTemplate(
            id: "fivebyfive", name: "5×5 fuerza",
            summary: "Tres básicos por sesión, cinco series de cinco. Subes peso cada vez que completas.",
            level: .intermediate, goals: [.strength], mode: .sequence, sessionsPerWeek: 3,
            sessions: [
                ("Fuerza A", [ProgramItem(name: "Sentadilla", sets: 5, reps: 5, rest: 180, main: true),
                              ProgramItem(name: "Press de banca", sets: 5, reps: 5, rest: 180, main: true),
                              ProgramItem(name: "Remo con barra", sets: 5, reps: 5, rest: 150, main: true)]),
                ("Fuerza B", [ProgramItem(name: "Sentadilla", sets: 5, reps: 5, rest: 180, main: true),
                              ProgramItem(name: "Press militar", sets: 5, reps: 5, rest: 180, main: true),
                              ProgramItem(name: "Peso muerto", sets: 1, reps: 5, rest: 180)]),
            ],
            weeks: (1...12).map { n in
                n % 4 == 0
                    ? ProgramWeek(label: String(localized: "Semana \(n) · descarga"), setsDelta: -2, load: 0.9, note: "Tres series al 90 %. Descansa las articulaciones.")
                    : ProgramWeek(label: String(localized: "Semana \(n)"), rpe: n < 4 ? 7 : n < 8 ? 8 : 9,
                                  note: "Si completas las 5×5, la próxima vez sube 2,5 kg.")
            }),
        ProgramTemplate(
            id: "homedb", name: "Casa con mancuernas",
            summary: "Tres sesiones a la semana con mancuernas y un banco, el día que puedas.",
            level: .beginner, goals: [.hypertrophy, .fatLoss, .health], mode: .elasticWeek, sessionsPerWeek: 3,
            sessions: [
                ("Casa A", [ProgramItem(name: "Sentadilla goblet", sets: 3, reps: 12, main: true),
                            ProgramItem(name: "Press de banca con mancuernas", sets: 3, reps: 10, main: true),
                            ProgramItem(name: "Remo con mancuerna", sets: 3, reps: 10, main: true),
                            ProgramItem(name: "Plancha", sets: 3, reps: 0, rest: 60)]),
                ("Casa B", [ProgramItem(name: "Sentadilla búlgara", sets: 3, reps: 10, main: true),
                            ProgramItem(name: "Press de hombros con mancuernas", sets: 3, reps: 10, main: true),
                            ProgramItem(name: "Curl con mancuernas", sets: 3, reps: 12, rest: 60),
                            ProgramItem(name: "Extensión de tríceps sobre la cabeza", sets: 3, reps: 12, rest: 60),
                            ProgramItem(name: "Dead bug", sets: 3, reps: 12, rest: 60)]),
                ("Casa C", [ProgramItem(name: "Subida al banco", sets: 3, reps: 10, main: true),
                            ProgramItem(name: "Press inclinado mancuernas", sets: 3, reps: 10, main: true),
                            ProgramItem(name: "Remo con mancuerna", sets: 3, reps: 12),
                            ProgramItem(name: "Elevaciones laterales", sets: 3, reps: 15, rest: 60),
                            ProgramItem(name: "Russian twist", sets: 3, reps: 20, rest: 60)]),
            ],
            weeks: blocks(8)),
        ProgramTemplate(
            id: "bodyweight", name: "Peso corporal",
            summary: "Sin material, en casa o de viaje. Cada semana, un par de repeticiones más.",
            level: .beginner, goals: [.health, .fatLoss, .endurance], mode: .elasticWeek, sessionsPerWeek: 3,
            sessions: [
                ("Cuerpo A", [ProgramItem(name: "Sentadilla sin peso", sets: 3, reps: 15, rest: 60, main: true),
                              ProgramItem(name: "Flexiones", sets: 3, reps: 8, rest: 60, main: true),
                              ProgramItem(name: "Puente de glúteo", sets: 3, reps: 15, rest: 60, main: true),
                              ProgramItem(name: "Plancha", sets: 3, reps: 0, rest: 45),
                              ProgramItem(name: "Escaladores", sets: 3, reps: 0, rest: 45)]),
                ("Cuerpo B", [ProgramItem(name: "Puente de glúteo a una pierna", sets: 3, reps: 10, rest: 60, main: true),
                              ProgramItem(name: "Flexiones en pica", sets: 3, reps: 6, rest: 60, main: true),
                              ProgramItem(name: "Flexiones diamante", sets: 3, reps: 6, rest: 60, main: true),
                              ProgramItem(name: "Dead bug", sets: 3, reps: 12, rest: 45),
                              ProgramItem(name: "Burpees", sets: 3, reps: 8, rest: 60)]),
                ("Cuerpo C", [ProgramItem(name: "Sentadilla sin peso", sets: 4, reps: 15, rest: 60, main: true),
                              ProgramItem(name: "Flexiones", sets: 4, reps: 8, rest: 60, main: true),
                              ProgramItem(name: "Plancha lateral", sets: 3, reps: 0, rest: 45),
                              ProgramItem(name: "Bird dog", sets: 3, reps: 10, rest: 45),
                              ProgramItem(name: "Jumping jacks", sets: 3, reps: 0, rest: 45)]),
            ],
            weeks: (1...8).map { n in
                n % 4 == 0
                    ? ProgramWeek(label: String(localized: "Semana \(n) · descarga"), setsDelta: -1, note: "Una serie menos: recupera.")
                    : ProgramWeek(label: String(localized: "Semana \(n)"), repsDelta: 2 * ((n - 1) - (n - 1) / 4), rpe: 8,
                                  note: "Dos repeticiones más que la semana pasada en los principales.")
            }),
    ]

    static func template(_ id: String) -> ProgramTemplate? { all.first { $0.id == id } }

    /// Las que encajan con el perfil y el material, la mejor primero.
    static func recommended(for profile: TrainingProfile, equipment: EquipmentProfile) -> [ProgramTemplate] {
        func score(_ t: ProgramTemplate) -> Int {
            var s = 0
            if t.fits(equipment) { s += 100 }
            if t.goals.contains(profile.goal) { s += 20 }
            if t.level == profile.level { s += 10 }
            s -= abs(t.sessionsPerWeek - profile.daysPerWeek) * 5
            return s
        }
        return all.sorted { score($0) > score($1) }
    }
}

extension WorkoutViewModel {

    var activeProgram: ActiveProgram? {
        get { userDefaults.data(forKey: "ActiveProgram").flatMap { try? JSONDecoder().decode(ActiveProgram.self, from: $0) } }
        set {
            if let p = newValue, let d = try? JSONEncoder().encode(p) { userDefaults.set(d, forKey: "ActiveProgram") }
            else { userDefaults.removeObject(forKey: "ActiveProgram") }
            objectWillChange.send()
        }
    }

    /// Semana del programa (índice desde 0). nil si no hay programa o no es la rutina activa.
    func programWeek(now: Date = Date()) -> (index: Int, week: ProgramWeek, finished: Bool)? {
        guard let p = activeProgram, p.routineName == activeRoutineName, !p.weeks.isEmpty else { return nil }
        let cal = Calendar.current
        let raw: Int
        if p.bySessions {
            let start = cal.startOfDay(for: p.start)
            let sessions = workoutHistory.filter { $0.key >= start && $0.value.values.contains { $0.contains { $0.completedSets > 0 } } }.count
            raw = sessions / max(1, p.sessionsPerWeek)
        } else {
            raw = max(0, cal.dateComponents([.day], from: cal.startOfDay(for: p.start), to: cal.startOfDay(for: now)).day ?? 0) / 7
        }
        let finished = raw >= p.weeks.count
        let i = min(raw, p.weeks.count - 1)
        return (i, p.weeks[i], finished)
    }

    /// Crea la rutina del programa, la activa y aplica la primera semana.
    func startProgram(_ t: ProgramTemplate, now: Date = Date()) {
        endProgram()   // si había otro, sus ejercicios vuelven a como estaban
        var plan: [WorkoutDay: [WorkoutExercise]] = Dictionary(uniqueKeysWithValues: WorkoutDay.allCases.map { ($0, []) })
        var labels: [WorkoutDay: String] = [:]
        var base: [UUID: ActiveProgram.Target] = [:]
        var original: [UUID: ActiveProgram.Target] = [:]
        for (slot, session) in zip(t.slots, t.sessions) {
            labels[slot] = session.label
            for item in session.items {
                guard let c = ExerciseCatalog.entry(named: item.name) else { continue }
                let existed = availableExercises.contains { ExerciseLibrary.fold($0.name) == ExerciseLibrary.fold(c.name) }
                let ex = exerciseFromCatalog(c)
                if existed, original[ex.id] == nil { original[ex.id] = .init(sets: ex.totalSets, reps: ex.repetitions, main: item.main) }
                if let i = availableExercises.firstIndex(where: { $0.id == ex.id }) {
                    availableExercises[i].totalSets = item.sets
                    if availableExercises[i].segundos == 0 { availableExercises[i].repetitions = item.reps }
                    availableExercises[i].restDuration = item.rest
                }
                // El mismo ejercicio en dos sesiones: manda la versión principal.
                if base[ex.id] == nil || item.main { base[ex.id] = .init(sets: item.sets, reps: item.reps, main: item.main) }
                plan[slot, default: []].append(WorkoutExercise(exerciseId: ex.id))
            }
        }
        var routine = Routine(name: uniqueRoutineName(t.name), plan: plan, dayLabels: labels, activeDays: t.slots)
        routine.mode = t.mode
        activate(routine)
        activeProgram = ActiveProgram(templateId: t.id, name: t.name, routineName: routine.name, start: now,
                                      weeks: t.weeks, sessionsPerWeek: t.sessionsPerWeek, base: base, original: original)
        syncProgramWeek()
        weeklySessionGoal = min(7, t.sessionsPerWeek)
    }

    private func uniqueRoutineName(_ name: String) -> String {
        let taken = Set(savedRoutines.map(\.name) + [activeRoutineName])
        guard taken.contains(name) else { return name }
        var n = 2
        while taken.contains("\(name) \(n)") { n += 1 }
        return "\(name) \(n)"
    }

    /// Aplica las series y repeticiones de la semana en curso (si ha cambiado).
    func syncProgramWeek() {
        guard var p = activeProgram, let w = programWeek() else { return }
        let target = w.finished ? p.weeks.count : w.index
        guard target != p.appliedWeek else { return }
        for (id, t) in p.base {
            guard let i = availableExercises.firstIndex(where: { $0.id == id }) else { continue }
            if w.finished {
                availableExercises[i].totalSets = t.sets
                if availableExercises[i].segundos == 0 { availableExercises[i].repetitions = t.reps }
                continue
            }
            let week = w.week
            let sets = t.main ? t.sets + week.setsDelta : t.sets - (week.deload ? 1 : 0)
            availableExercises[i].totalSets = max(1, sets)
            if availableExercises[i].segundos == 0 {
                availableExercises[i].repetitions = max(1, t.main ? t.reps + week.repsDelta : t.reps)
            }
        }
        p.appliedWeek = target
        activeProgram = p
        persistAll()
        publishSummary()
    }

    /// Quita el programa: sus ejercicios vuelven a las series de antes (la rutina se queda).
    func endProgram() {
        guard let p = activeProgram else { return }
        for (id, t) in p.original {
            guard let i = availableExercises.firstIndex(where: { $0.id == id }) else { continue }
            availableExercises[i].totalSets = t.sets
            if availableExercises[i].segundos == 0 { availableExercises[i].repetitions = t.reps }
        }
        activeProgram = nil
        persistAll()
    }

    /// Vuelve a empezar el mismo programa desde la semana 1.
    func restartProgram(now: Date = Date()) {
        guard var p = activeProgram else { return }
        p.start = now
        p.appliedWeek = -1
        activeProgram = p
        syncProgramWeek()
    }

    /// ¿Este ejercicio está en el programa en curso?
    func inProgram(_ exerciseId: UUID) -> Bool { programWeek() != nil && activeProgram?.base[exerciseId] != nil }
}
