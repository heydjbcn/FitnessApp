//
//  Routine.swift
//  ChamaFit
//
//  Varias rutinas guardadas ("Fuerza", "Hipertrofia", "Verano"): cada una es
//  una plantilla semanal con sus nombres de sesión y sus días activos. La
//  activa es la que vive en `dailyWorkoutRecords`; las demás esperan aquí.
//  La biblioteca de ejercicios es común a todas.
//

import Foundation
import Combine

struct Routine: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var plan: [WorkoutDay: [WorkoutExercise]]
    var dayLabels: [WorkoutDay: String]
    var activeDays: [WorkoutDay]
    var updatedAt = Date()
    var mode: ScheduleMode = .fixedWeek
    /// Superseries que son circuito, AMRAP o EMOM.
    var blocks: [String: BlockSettings] = [:]

    init(id: UUID = UUID(), name: String, plan: [WorkoutDay: [WorkoutExercise]],
         dayLabels: [WorkoutDay: String], activeDays: [WorkoutDay], updatedAt: Date = Date()) {
        self.id = id; self.name = name; self.plan = plan
        self.dayLabels = dayLabels; self.activeDays = activeDays; self.updatedAt = updatedAt
    }

    /// Tolerante con copias antiguas o campos que falten: nunca tira todas las rutinas.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Rutina"
        plan = try c.decodeIfPresent([WorkoutDay: [WorkoutExercise]].self, forKey: .plan) ?? [:]
        dayLabels = try c.decodeIfPresent([WorkoutDay: String].self, forKey: .dayLabels) ?? [:]
        activeDays = try c.decodeIfPresent([WorkoutDay].self, forKey: .activeDays) ?? WorkoutDay.allCases
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        mode = (try? c.decodeIfPresent(ScheduleMode.self, forKey: .mode)) ?? .fixedWeek
        blocks = (try? c.decodeIfPresent([String: BlockSettings].self, forKey: .blocks)) ?? [:]
    }

    /// Ejercicios distintos y series totales de la semana, para la lista.
    var summary: String {
        let records = plan.values.flatMap { $0 }
        let days = plan.filter { !$0.value.isEmpty }.count
        return String(localized: "\(days) días · \(records.count) ejercicios")
    }
}

extension WorkoutViewModel {

    private static let routinesKey = "Routines"
    private static let activeNameKey = "ActiveRoutineName"

    /// Nombre de la rutina activa (la de la plantilla).
    var activeRoutineName: String {
        get { userDefaults.string(forKey: Self.activeNameKey) ?? "Mi rutina" }
        set { userDefaults.set(newValue, forKey: Self.activeNameKey); objectWillChange.send() }
    }

    /// Las rutinas guardadas que NO están activas.
    var savedRoutines: [Routine] {
        get {
            if let cached = routinesCache { return cached }
            let list: [Routine]
            if let data = userDefaults.data(forKey: Self.routinesKey) {
                list = (try? JSONDecoder().decode([Routine].self, from: data)) ?? []
            } else {
                list = []
            }
            routinesCache = list
            return list
        }
        set {
            routinesCache = newValue
            if let data = try? JSONEncoder().encode(newValue) { userDefaults.set(data, forKey: Self.routinesKey) }
            objectWillChange.send()
        }
    }

    /// La plantilla actual empaquetada como rutina, sin el progreso de hoy.
    private func currentAsRoutine() -> Routine {
        var r = Routine(name: activeRoutineName,
                        plan: dailyWorkoutRecords.mapValues { $0.map { $0.resettingProgress() } },
                        dayLabels: dayLabels, activeDays: activeDays)
        r.mode = scheduleMode
        r.blocks = blockSettings
        return r
    }

    /// Guarda la actual en la estantería y pone otra en su sitio.
    func activate(_ routine: Routine) {
        ensureSession()
        var shelf = savedRoutines.filter { $0.id != routine.id }
        shelf.append(currentAsRoutine())
        savedRoutines = shelf
        dailyWorkoutRecords = routine.plan
        for day in WorkoutDay.allCases where dailyWorkoutRecords[day] == nil { dailyWorkoutRecords[day] = [] }
        dayLabels = routine.dayLabels
        activeDays = routine.activeDays
        activeRoutineName = routine.name
        scheduleMode = routine.mode
        blockSettings = routine.blocks
        trainingDay = todaySession
        HapticManager.shared.success()
        persistAll()
        publishSummary()
        SystemCalendar.sync(self)
    }

    /// Nueva rutina vacía (o copia de la actual) y la activa.
    func createRoutine(named name: String, copyingCurrent: Bool) {
        let clean = name.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return }
        let plan: [WorkoutDay: [WorkoutExercise]] = copyingCurrent
            ? dailyWorkoutRecords.mapValues { $0.map { WorkoutExercise(exerciseId: $0.exerciseId, supersetGroup: $0.supersetGroup) } }
            : Dictionary(uniqueKeysWithValues: WorkoutDay.allCases.map { ($0, []) })
        var routine = Routine(name: clean, plan: plan,
                              dayLabels: copyingCurrent ? dayLabels : [:],
                              activeDays: copyingCurrent ? activeDays : WorkoutDay.allCases)
        routine.mode = copyingCurrent ? scheduleMode : .fixedWeek
        routine.blocks = copyingCurrent ? blockSettings : [:]
        activate(routine)
    }

    func renameActiveRoutine(_ name: String) {
        let clean = name.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return }
        activeRoutineName = clean
    }

    func deleteRoutine(_ routine: Routine) {
        savedRoutines = savedRoutines.filter { $0.id != routine.id }
        HapticManager.shared.destructiveAction()
    }

    // MARK: - Orden de los ejercicios de un día

    func moveExercise(in day: WorkoutDay, from source: Int, to destination: Int) {
        guard var list = dailyWorkoutRecords[day], list.indices.contains(source),
              list.indices.contains(destination), source != destination else { return }
        let item = list.remove(at: source)
        list.insert(item, at: destination)
        dailyWorkoutRecords[day] = list
        HapticManager.shared.selectionFeedback()
        persistAll()
        if day == trainingDay { publishSummary() }
        PhoneConnectivity.shared.sendTodayContext()
    }
}
