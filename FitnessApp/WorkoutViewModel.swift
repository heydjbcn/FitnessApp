//
//  WorkoutViewModel.swift
//  ChamaFit
//
//  Estado de la app: biblioteca de ejercicios, plantilla semanal con el progreso
//  de HOY, historial por fecha, peso corporal y temporizador de descanso.
//
//  Modelo de sesión: `dailyWorkoutRecords` es la plantilla (qué toca cada día)
//  y lleva las series marcadas de la sesión de HOY. Cada cambio se refleja en
//  `workoutHistory[fechaDeHoy]`. Al abrir la app en un día nuevo, el progreso
//  se archiva bajo su fecha y la plantilla vuelve a cero. Todas las cifras de
//  progreso (semana, récords, gráficas) salen del historial.
//

import SwiftUI
import Combine
import Foundation
import WidgetKit

final class WorkoutViewModel: ObservableObject {

    // MARK: - Estado

    @Published var activeDays: [WorkoutDay] = WorkoutDay.allCases
    /// Biblioteca: las definiciones únicas de cada ejercicio.
    @Published var availableExercises: [Exercise] = []
    /// Plantilla semanal + progreso de la sesión de hoy.
    @Published var dailyWorkoutRecords: [WorkoutDay: [WorkoutExercise]] = [:]
    /// Lo hecho cada fecha: qué día de rutina se entrenó y con qué series.
    @Published var workoutHistory: [Date: [WorkoutDay: [WorkoutExercise]]] = [:]
    @Published var bodyWeightHistory: [Date: Double] = [:]

    /// Nombre que el usuario le pone a cada día ("Hombro y core", "Pierna"…).
    @Published var dayLabels: [WorkoutDay: String] = [:] {
        didSet { persistSmall(dayLabels, key: "DayLabels") }
    }
    /// Nota libre de cada sesión, por fecha.
    @Published var sessionNotes: [Date: String] = [:] {
        didSet { persistSmall(sessionNotes, key: "SessionNotes") }
    }
    /// Centro de avisos: fin de descanso, récords, recordatorios.
    @Published var notifications: [AppNotification] = [] {
        didSet { persistSmall(notifications, key: "AppNotifications") }
    }
    @Published var notificationsEnabled: Bool = true {
        didSet { userDefaults.set(notificationsEnabled, forKey: "NotificationsEnabled") }
    }
    /// Descanso con el que nacen los ejercicios nuevos (Configuración).
    @Published var defaultRestDuration: Int = 120 {
        didSet { userDefaults.set(defaultRestDuration, forKey: "RestDuration") }
    }

    // Temporizador de descanso
    @Published var timerActive = false
    @Published var timeRemaining = 120
    @Published var currentTimerDuration: Int = 120
    /// Qué descanso es: "Press militar · siguiente serie 3 de 4".
    @Published var timerLabel: String = ""
    @Published var isTimerEnabled = true
    /// Hora a la que termina el descanso. La cuenta se hace contra el reloj de
    /// pared, así que sobrevive a que la app se vaya al fondo.
    @Published private(set) var timerEndDate: Date? = nil

    /// Mensaje de celebración cuando se bate un récord (lo observa la UI).
    @Published var prCelebration: String? = nil

    /// Colores con los que se pinta la Live Activity (los pone ContentView según el tema).
    var activityStyle = ActivityStyle()
    /// Día que se está entrenando en Inicio (para el reloj y el widget).
    var trainingDay: WorkoutDay = WeeklyCalendarView.getCurrentDay() {
        didSet { if trainingDay != oldValue { publishSummary() } }
    }

    /// Fecha (inicio de día) de la sesión que lleva la plantilla.
    private(set) var sessionDate: Date

    private var timer: Timer?
    let userDefaults = UserDefaults.standard
    private var pendingSave: DispatchWorkItem?
    private let saveQueue = DispatchQueue(label: "chamafit.save", qos: .utility)
    private let liveActivity = LiveActivityManager()

    // MARK: - Ciclo de vida

    init() {
        sessionDate = Calendar.current.startOfDay(for: Date())
        WorkoutDay.allCases.forEach { dailyWorkoutRecords[$0] = [] }
        loadData()
        ensureSession()
        liveActivity.endAllOrphans()
        // Los botones de la Live Activity (+30 s / Parar) llegan por aquí.
        RestTimerBridge.shared.extend = { [weak self] in self?.extendTimer(by: 30) }
        RestTimerBridge.shared.stop = { [weak self] in self?.stopTimer() }
        publishSummary()
    }

    /// Deja en el App Group el resumen de la sesión para el widget y refresca.
    func publishSummary() {
        let day = trainingDay
        let records = dailyWorkoutRecords[day] ?? []
        let next = records.first { r in
            guard let ex = getExercise(by: r.exerciseId) else { return false }
            return r.completedSets < ex.totalSets
        }.flatMap { getExercise(by: $0.exerciseId)?.name }
        TodaySummary(dayName: day.displayName, sessionLabel: label(for: day),
                     exerciseCount: records.count, doneSets: completedSets(for: day),
                     totalSets: totalSets(for: day), nextExercise: next,
                     streak: consecutiveWorkoutDays(), accent1: activityStyle.accent1,
                     accent2: activityStyle.accent2, onAccentDark: activityStyle.onAccentDark).save()
        WidgetCenter.shared.reloadTimelines(ofKind: "ChamaFitToday")
    }

    /// Si ha cambiado el día desde la última sesión, archiva el progreso bajo
    /// su fecha y deja la plantilla a cero. Se llama al arrancar, al volver del
    /// fondo y antes de cualquier cambio en las series.
    func ensureSession() {
        let today = Calendar.current.startOfDay(for: Date())
        guard sessionDate < today else { return }
        for day in WorkoutDay.allCases {
            mirrorToHistory(day, on: sessionDate)
            dailyWorkoutRecords[day] = (dailyWorkoutRecords[day] ?? []).map { $0.resettingProgress() }
        }
        sessionDate = today
        userDefaults.set(today, forKey: "LastSessionDate")
        scheduleSave()
    }

    func getExercise(by id: UUID) -> Exercise? {
        availableExercises.first { $0.id == id }
    }

    // MARK: - Historial

    /// Copia la sesión de un día de rutina al historial de una fecha. Si ese
    /// día no tiene ninguna serie hecha, no deja rastro (así tocar una
    /// superserie o quitar un ejercicio no marca el día como entrenado).
    private func mirrorToHistory(_ day: WorkoutDay, on date: Date) {
        var byDay = workoutHistory[date] ?? [:]
        let records = dailyWorkoutRecords[day] ?? []
        if records.contains(where: { $0.completedSets > 0 }) {
            byDay[day] = records
        } else {
            byDay.removeValue(forKey: day)
        }
        if byDay.isEmpty { workoutHistory.removeValue(forKey: date) } else { workoutHistory[date] = byDay }
    }

    private func recordHistory(for day: WorkoutDay) {
        ensureSession()
        mirrorToHistory(day, on: sessionDate)
        scheduleSave()
        if day == trainingDay { publishSummary() }
        PhoneConnectivity.shared.sendTodayContext()
    }

    func exercisesForDate(_ date: Date) -> [WorkoutDay: [WorkoutExercise]]? {
        workoutHistory[Calendar.current.startOfDay(for: date)]
    }

    /// True si ese día se hizo al menos una serie.
    func hasWorkoutForDate(_ date: Date) -> Bool {
        guard let byDay = exercisesForDate(date) else { return false }
        return byDay.values.contains { $0.contains { $0.completedSets > 0 } }
    }

    // MARK: - Series

    /// Marca la siguiente serie. Sin `weight`/`reps` nace con lo de la última
    /// vez (o con la plantilla); con ellos, con lo que se haya escrito.
    func completeSet(for workoutExerciseId: UUID, in day: WorkoutDay,
                     weight: Double? = nil, reps: Int? = nil, type: SetType = .normal, rpe: Int? = nil) {
        ensureSession()
        guard let idx = dailyWorkoutRecords[day]?.firstIndex(where: { $0.id == workoutExerciseId }),
              let exercise = getExercise(by: dailyWorkoutRecords[day]![idx].exerciseId) else { return }

        var record = dailyWorkoutRecords[day]![idx]
        guard record.completedSets < exercise.totalSets else { return }

        let last = lastPerformance(for: exercise.id)
        let log = SetLog(reps: reps ?? last?.reps ?? exercise.repetitions,
                         weight: weight ?? last?.weight ?? exercise.weight,
                         type: type, rpe: rpe)
        record.setLogs.append(log)
        record.completedSets += 1
        record.lastSetCompletedAt = Date()
        dailyWorkoutRecords[day]![idx] = record
        recordHistory(for: day)
        checkRecord(weight: log.weight, exerciseId: exercise.id, excluding: log.id, name: exercise.name)
        HapticManager.shared.setCompleted()

        guard record.completedSets < exercise.totalSets else { return }

        // En una superserie el descanso llega al cerrar la vuelta: si el
        // compañero de grupo va por detrás, todavía toca hacer su serie.
        if let g = record.supersetGroup {
            let partners = (dailyWorkoutRecords[day] ?? []).filter { $0.supersetGroup == g && $0.id != record.id }
            if partners.contains(where: { $0.completedSets < record.completedSets }) {
                let next = partners.first { $0.completedSets < record.completedSets }
                    .flatMap { getExercise(by: $0.exerciseId)?.name } ?? "el siguiente"
                timerLabel = "Ahora \(next) · sin descanso"
                return
            }
        }
        timerLabel = "\(exercise.name) · siguiente serie \(record.completedSets + 1) de \(exercise.totalSets)"
        startTimer(duration: exercise.restDuration, isEnabled: isTimerEnabled)
    }

    func undoLastSet(for workoutExerciseId: UUID, in day: WorkoutDay) {
        ensureSession()
        guard let idx = dailyWorkoutRecords[day]?.firstIndex(where: { $0.id == workoutExerciseId }) else { return }
        var record = dailyWorkoutRecords[day]![idx]
        guard record.completedSets > 0 else { return }
        record.completedSets -= 1
        if !record.setLogs.isEmpty { record.setLogs.removeLast() }
        if record.completedSets == 0 { record.lastSetCompletedAt = nil }
        dailyWorkoutRecords[day]![idx] = record
        recordHistory(for: day)
        HapticManager.shared.warning()
    }

    /// Edición manual de una serie ya hecha (peso, reps, tipo, RPE).
    func updateSetLog(_ updated: SetLog, for workoutExerciseId: UUID, in day: WorkoutDay) {
        guard let idx = dailyWorkoutRecords[day]?.firstIndex(where: { $0.id == workoutExerciseId }),
              let logIdx = dailyWorkoutRecords[day]![idx].setLogs.firstIndex(where: { $0.id == updated.id }) else { return }
        dailyWorkoutRecords[day]![idx].setLogs[logIdx] = updated
        recordHistory(for: day)
        if let ex = getExercise(by: dailyWorkoutRecords[day]![idx].exerciseId) {
            checkRecord(weight: updated.weight, exerciseId: ex.id, excluding: updated.id, name: ex.name)
        }
    }

    func setSupersetGroup(_ group: Int?, for workoutExerciseId: UUID, in day: WorkoutDay) {
        guard let idx = dailyWorkoutRecords[day]?.firstIndex(where: { $0.id == workoutExerciseId }) else { return }
        dailyWorkoutRecords[day]![idx].supersetGroup = group
        recordHistory(for: day)
    }

    func removeExercise(recordId: UUID, from day: WorkoutDay) {
        dailyWorkoutRecords[day]?.removeAll { $0.id == recordId }
        recordHistory(for: day)
    }

    // MARK: - Rendimiento y récords

    /// Todas las series registradas de un ejercicio. Salen del historial, que
    /// incluye la sesión de hoy: cada serie cuenta una sola vez.
    func allSetLogs(for exerciseId: UUID) -> [SetLog] {
        workoutHistory.values.flatMap { byDay in
            byDay.values.flatMap { records in
                records.filter { $0.exerciseId == exerciseId }.flatMap(\.setLogs)
            }
        }
    }

    /// Última serie de trabajo de un ejercicio. Ignora calentamientos y drops
    /// para no arrastrar un peso bajo a la siguiente serie.
    func lastPerformance(for exerciseId: UUID) -> SetLog? {
        let logs = allSetLogs(for: exerciseId)
        let work = logs.filter { $0.type == .normal || $0.type == .failure }
        return (work.isEmpty ? logs : work).max { $0.date < $1.date }
    }

    func bestWeight(for exerciseId: UUID, excluding logId: UUID? = nil) -> Double {
        allSetLogs(for: exerciseId).filter { $0.id != logId }.map(\.weight).max() ?? 0
    }

    /// Récord personal: mejor peso y mejor 1RM estimado (Epley).
    func personalRecord(for exerciseId: UUID) -> (weight: Double, oneRepMax: Double)? {
        let logs = allSetLogs(for: exerciseId).filter { $0.weight > 0 }
        guard !logs.isEmpty else { return nil }
        return (logs.map(\.weight).max() ?? 0, logs.map(\.estimatedOneRepMax).max() ?? 0)
    }

    /// Fecha en la que se hizo el mejor peso de un ejercicio.
    func recordDate(for exerciseId: UUID) -> Date? {
        allSetLogs(for: exerciseId).filter { $0.weight > 0 }.max { $0.weight < $1.weight }?.date
    }

    private func checkRecord(weight: Double, exerciseId: UUID, excluding logId: UUID?, name: String) {
        guard weight > 0 else { return }
        let previous = bestWeight(for: exerciseId, excluding: logId)
        guard weight > previous else { return }
        if previous > 0 {
            prCelebration = "¡Nuevo récord en \(name)! \(Self.kg(weight))"
            notify(.achievement, title: "¡Nuevo récord!",
                   message: "\(name): \(Self.kg(weight)). Superaste tu marca anterior de \(Self.kg(previous)).")
        } else {
            prCelebration = "Primera marca en \(name): \(Self.kg(weight))"
            notify(.achievement, title: "Primera marca",
                   message: "\(name): \(Self.kg(weight)). A partir de aquí, a superarla.")
        }
        HapticManager.shared.goalAchieved()
    }

    // MARK: - Series temporales para gráficas

    func exerciseDailyMaxWeight(for exerciseId: UUID) -> [(date: Date, weight: Double)] {
        let cal = Calendar.current
        var byDay: [Date: Double] = [:]
        for log in allSetLogs(for: exerciseId) where log.weight > 0 {
            let d = cal.startOfDay(for: log.date)
            byDay[d] = Swift.max(byDay[d] ?? 0, log.weight)
        }
        return byDay.map { (date: $0.key, weight: $0.value) }.sorted { $0.date < $1.date }
    }

    func exerciseDailyVolume(for exerciseId: UUID) -> [(date: Date, volume: Double)] {
        let cal = Calendar.current
        var byDay: [Date: Double] = [:]
        for log in allSetLogs(for: exerciseId) {
            let d = cal.startOfDay(for: log.date)
            byDay[d, default: 0] += log.volume
        }
        return byDay.map { (date: $0.key, volume: $0.value) }.sorted { $0.date < $1.date }
    }

    /// Mejor 1RM estimado por sesión.
    func exerciseDailyOneRepMax(for exerciseId: UUID) -> [(date: Date, oneRepMax: Double)] {
        let cal = Calendar.current
        var byDay: [Date: Double] = [:]
        for log in allSetLogs(for: exerciseId) where log.weight > 0 {
            let d = cal.startOfDay(for: log.date)
            byDay[d] = Swift.max(byDay[d] ?? 0, (log.estimatedOneRepMax * 10).rounded() / 10)
        }
        return byDay.map { (date: $0.key, oneRepMax: $0.value) }.sorted { $0.date < $1.date }
    }

    func bodyWeightSeries() -> [(date: Date, weight: Double)] {
        bodyWeightHistory.map { (date: $0.key, weight: $0.value) }.sorted { $0.date < $1.date }
    }

    func updateBodyWeight(for date: Date, weight: Double) {
        bodyWeightHistory[Calendar.current.startOfDay(for: date)] = weight
        HapticManager.shared.success()
        scheduleSave()
    }

    func bodyWeightForDate(_ date: Date) -> Double? {
        bodyWeightHistory[Calendar.current.startOfDay(for: date)]
    }

    // MARK: - Cifras de la sesión de un día (Inicio)

    /// Volumen (peso × reps) marcado hoy en un día de rutina.
    func volume(for day: WorkoutDay) -> Double {
        (dailyWorkoutRecords[day] ?? []).reduce(0) { $0 + $1.setLogs.reduce(0) { $0 + $1.volume } }
    }

    func completedSets(for day: WorkoutDay) -> Int {
        (dailyWorkoutRecords[day] ?? []).reduce(0) { $0 + $1.completedSets }
    }

    func totalSets(for day: WorkoutDay) -> Int {
        (dailyWorkoutRecords[day] ?? []).reduce(0) { $0 + (getExercise(by: $1.exerciseId)?.totalSets ?? 0) }
    }

    func progressForDay(_ day: WorkoutDay) -> Double {
        let total = totalSets(for: day)
        return total > 0 ? Double(completedSets(for: day)) / Double(total) : 0
    }

    /// Minutos que faltan: 3 por serie pendiente, como el prototipo.
    func remainingMinutes(for day: WorkoutDay) -> Int {
        max(0, totalSets(for: day) - completedSets(for: day)) * 3
    }

    func isDayComplete(_ day: WorkoutDay) -> Bool {
        let total = totalSets(for: day)
        return total > 0 && completedSets(for: day) >= total
    }

    func label(for day: WorkoutDay) -> String? {
        guard let l = dayLabels[day]?.trimmingCharacters(in: .whitespaces), !l.isEmpty else { return nil }
        return l
    }

    func setLabel(_ label: String, for day: WorkoutDay) {
        let clean = label.trimmingCharacters(in: .whitespaces)
        if clean.isEmpty { dayLabels.removeValue(forKey: day) } else { dayLabels[day] = clean }
    }

    // MARK: - Cifras de la semana (del historial)

    struct WeekStats {
        var sessions = 0
        var sets = 0
        var volume: Double = 0
        var minutes: Int { sets * 3 }
    }

    /// Semana natural (lunes a domingo) desplazada `offset` semanas desde la actual.
    func weekInterval(offset: Int = 0) -> DateInterval {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let base = cal.date(byAdding: .weekOfYear, value: offset, to: Date()) ?? Date()
        return cal.dateInterval(of: .weekOfYear, for: base) ?? DateInterval(start: base, duration: 7 * 86_400)
    }

    private func history(in interval: DateInterval) -> [(date: Date, byDay: [WorkoutDay: [WorkoutExercise]])] {
        workoutHistory.filter { interval.contains($0.key) }
            .map { (date: $0.key, byDay: $0.value) }
            .sorted { $0.date < $1.date }
    }

    func weekStats(offset: Int = 0) -> WeekStats {
        var s = WeekStats()
        for entry in history(in: weekInterval(offset: offset)) {
            let records = entry.byDay.values.flatMap { $0 }
            let done = records.reduce(0) { $0 + $1.completedSets }
            guard done > 0 else { continue }
            s.sessions += 1
            s.sets += done
            s.volume += records.flatMap(\.setLogs).reduce(0) { $0 + $1.volume }
        }
        return s
    }

    /// Volumen de la semana en curso.
    func weeklyVolume() -> Double { weekStats().volume }

    /// Series por grupo muscular en la semana en curso, ordenado de más a menos.
    func setsByMuscleGroup(weekOffset: Int = 0) -> [(group: String, sets: Int)] {
        var counts: [String: Int] = [:]
        for entry in history(in: weekInterval(offset: weekOffset)) {
            for record in entry.byDay.values.flatMap({ $0 }) where record.completedSets > 0 {
                let g = getExercise(by: record.exerciseId)?.muscleGroup ?? ""
                counts[g.isEmpty ? "Otros" : g, default: 0] += record.completedSets
            }
        }
        return counts.map { (group: $0.key, sets: $0.value) }.sorted { $0.sets > $1.sets }
    }

    /// El día de rutina mejor completado esta semana.
    func bestWorkoutDay() -> (day: WorkoutDay, pct: Double)? {
        var best: (WorkoutDay, Double)? = nil
        for entry in history(in: weekInterval()) {
            for (day, records) in entry.byDay {
                let total = records.reduce(0) { $0 + (getExercise(by: $1.exerciseId)?.totalSets ?? 0) }
                let done = records.reduce(0) { $0 + $1.completedSets }
                guard total > 0 else { continue }
                let pct = Double(done) / Double(total)
                if best == nil || pct > best!.1 { best = (day, pct) }
            }
        }
        return best.map { (day: $0.0, pct: $0.1) }
    }

    /// Días de entrenamiento seguidos. Un día sin rutina (descanso) no rompe la
    /// racha; un día con rutina y sin ninguna serie, sí.
    func consecutiveWorkoutDays() -> Int {
        let cal = Calendar.current
        var date = cal.startOfDay(for: Date())
        if !hasWorkoutForDate(date) { date = cal.date(byAdding: .day, value: -1, to: date)! }
        var streak = 0
        for _ in 0..<400 {
            if hasWorkoutForDate(date) {
                streak += 1
            } else if let day = WorkoutDay.from(date: date), !(dailyWorkoutRecords[day] ?? []).isEmpty {
                break
            }
            date = cal.date(byAdding: .day, value: -1, to: date)!
        }
        return streak
    }

    // MARK: - Biblioteca y plantilla

    func updateBaseExercise(_ updated: Exercise) {
        guard let i = availableExercises.firstIndex(where: { $0.id == updated.id }) else { return }
        availableExercises[i] = updated
        scheduleSave()
    }

    /// Quita el ejercicio de la biblioteca y de la plantilla. Lo ya hecho sigue
    /// en el historial, referenciado por id.
    func removeExercise(baseExercise: Exercise) {
        availableExercises.removeAll { $0.id == baseExercise.id }
        for day in WorkoutDay.allCases {
            dailyWorkoutRecords[day]?.removeAll { $0.exerciseId == baseExercise.id }
        }
        HapticManager.shared.exerciseDeleted()
        scheduleSave()
    }

    /// Duplica los ejercicios de un día a otro (sin progreso).
    func duplicateRoutine(from src: WorkoutDay, to dst: WorkoutDay) {
        let copies = (dailyWorkoutRecords[src] ?? []).map { WorkoutExercise(exerciseId: $0.exerciseId, supersetGroup: $0.supersetGroup) }
        dailyWorkoutRecords[dst, default: []].append(contentsOf: copies)
        scheduleSave()
        HapticManager.shared.success()
    }

    /// Deja la app vacía: biblioteca, plantilla, historial, peso y notas.
    /// No toca el perfil ni los ajustes.
    func resetAllData() {
        availableExercises = []
        dailyWorkoutRecords = Dictionary(uniqueKeysWithValues: WorkoutDay.allCases.map { ($0, []) })
        workoutHistory = [:]
        bodyWeightHistory = [:]
        activeDays = WorkoutDay.allCases
        dayLabels = [:]
        sessionNotes = [:]
        notifications = []
        saveNow()
    }

    // MARK: - Exportar

    /// Una fila por serie hecha: lo que de verdad se levantó, no la plantilla.
    func exportCSV() -> String {
        var rows = ["fecha,dia,ejercicio,serie,tipo,kg,reps,rpe"]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        for (date, byDay) in workoutHistory.sorted(by: { $0.key < $1.key }) {
            for day in byDay.keys.sorted(by: { $0.weekOrder < $1.weekOrder }) {
                for record in byDay[day] ?? [] where record.completedSets > 0 {
                    let name = (getExercise(by: record.exerciseId)?.name ?? "Ejercicio borrado")
                        .replacingOccurrences(of: "\"", with: "'")
                    for (i, log) in record.setLogs.enumerated() {
                        let kg = String(format: "%g", log.weight)
                        rows.append("\(df.string(from: date)),\(day.rawValue),\"\(name)\",\(i + 1),\(log.type.rawValue),\(kg),\(log.reps),\(log.rpe.map(String.init) ?? "")")
                    }
                    // Registros antiguos sin series detalladas: una fila por serie sin datos.
                    if record.setLogs.isEmpty {
                        for i in 0..<record.completedSets {
                            rows.append("\(df.string(from: date)),\(day.rawValue),\"\(name)\",\(i + 1),normal,,,")
                        }
                    }
                }
            }
        }
        return rows.joined(separator: "\n")
    }

    // MARK: - Temporizador de descanso

    private var sessionName: String {
        let day = trainingDay
        return label(for: day).map { "\(day.displayName) · \($0)" } ?? day.displayName
    }

    func startTimer(duration: Int, isEnabled: Bool = true) {
        guard isEnabled, duration > 0 else { return }
        stopTimer(silent: true)
        let end = Date().addingTimeInterval(TimeInterval(duration))
        timerEndDate = end
        currentTimerDuration = duration
        timeRemaining = duration
        timerActive = true
        HapticManager.shared.timerStarted()
        // El permiso de avisos se pide aquí, en el primer descanso, no al arrancar.
        NotificationManager.shared.ensurePermission()
        NotificationManager.shared.scheduleRestNotification(after: TimeInterval(duration))
        liveActivity.start(endDate: end, label: timerLabel.isEmpty ? "Descanso" : timerLabel,
                           sessionName: sessionName, style: activityStyle)
        PhoneConnectivity.shared.sendTimer(endDate: end, label: timerLabel)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.tick() }
        }
    }

    /// Recalcula lo que queda contra el reloj de pared (también al volver del fondo).
    func tick() {
        guard timerActive, let end = timerEndDate else { return }
        let remaining = Int(ceil(end.timeIntervalSinceNow))
        if remaining <= 0 {
            completeTimer()
        } else if remaining != timeRemaining {
            timeRemaining = remaining
        }
    }

    /// Alarga el descanso en curso (+30 s) y reprograma el aviso.
    func extendTimer(by seconds: Int) {
        guard timerActive, let end = timerEndDate else { return }
        let newEnd = end.addingTimeInterval(TimeInterval(seconds))
        timerEndDate = newEnd
        currentTimerDuration += seconds
        tick()
        NotificationManager.shared.cancelRestNotification()
        NotificationManager.shared.scheduleRestNotification(after: TimeInterval(timeRemaining))
        liveActivity.update(endDate: newEnd)
        PhoneConnectivity.shared.sendTimer(endDate: newEnd, label: timerLabel)
        HapticManager.shared.buttonTapped()
    }

    func stopTimer(silent: Bool = false) {
        timer?.invalidate()
        timer = nil
        let wasActive = timerActive
        timerActive = false
        timerEndDate = nil
        timeRemaining = currentTimerDuration
        if !silent { HapticManager.shared.timerStopped() }
        NotificationManager.shared.cancelRestNotification()
        liveActivity.end()
        if wasActive { PhoneConnectivity.shared.sendTimer(endDate: nil, label: "") }
    }

    private func completeTimer() {
        timer?.invalidate()
        timer = nil
        timerActive = false
        timerEndDate = nil
        timeRemaining = currentTimerDuration
        liveActivity.finish()
        PhoneConnectivity.shared.sendTimer(endDate: nil, label: "")
        HapticManager.shared.timerCompleted()
        notify(.restTimer, title: "Descanso terminado", message: "Cuando quieras, a por la siguiente serie.")
    }

    func updateTimerEnabledState(_ isEnabled: Bool) {
        isTimerEnabled = isEnabled
    }

    // MARK: - Persistencia

    /// Lo que se guarda en bloque. Se captura en el hilo principal y se
    /// codifica en segundo plano: el estado @Published no se toca fuera de main.
    private struct Snapshot: Encodable, Sendable {
        let exercises: [Exercise]
        let plan: [WorkoutDay: [WorkoutExercise]]
        let history: [Date: [WorkoutDay: [WorkoutExercise]]]
        let bodyWeight: [Date: Double]
        let activeDays: [WorkoutDay]
    }

    private func snapshot() -> Snapshot {
        Snapshot(exercises: availableExercises, plan: dailyWorkoutRecords,
                 history: workoutHistory, bodyWeight: bodyWeightHistory, activeDays: activeDays)
    }

    /// Guarda todo el estado (para las extensiones).
    func persistAll() { scheduleSave() }

    /// Agrupa los guardados: escribir por cada pulsación de tecla era lo que
    /// hacía la app antes.
    private func scheduleSave() {
        pendingSave?.cancel()
        let snap = snapshot()
        let work = DispatchWorkItem { Self.write(snap) }
        pendingSave = work
        saveQueue.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    /// Guarda sin esperar (al irse la app al fondo, tras restaurar una copia…).
    func saveNow() {
        pendingSave?.cancel()
        pendingSave = nil
        Self.write(snapshot())
    }

    nonisolated private static func write(_ snap: Snapshot) {
        let encoder = JSONEncoder()
        let defaults = UserDefaults.standard
        func put<T: Encodable>(_ value: T, _ key: String) {
            if let data = try? encoder.encode(value) { defaults.set(data, forKey: key) }
        }
        put(snap.exercises, "AvailableExercises")
        put(snap.plan, "DailyWorkoutRecords")
        put(snap.history, "WorkoutHistory")
        put(snap.bodyWeight, "BodyWeightHistory")
        put(snap.activeDays, "ActiveDays")
    }

    private func persistSmall<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { userDefaults.set(data, forKey: key) }
    }

    private func loadData() {
        let decoder = JSONDecoder()
        func get<T: Decodable>(_ key: String, _ type: T.Type) -> T? {
            guard let data = userDefaults.data(forKey: key) else { return nil }
            return try? decoder.decode(type, from: data)
        }

        availableExercises = get("AvailableExercises", [Exercise].self) ?? []
        dailyWorkoutRecords = get("DailyWorkoutRecords", [WorkoutDay: [WorkoutExercise]].self) ?? [:]
        workoutHistory = get("WorkoutHistory", [Date: [WorkoutDay: [WorkoutExercise]]].self) ?? [:]
        bodyWeightHistory = get("BodyWeightHistory", [Date: Double].self) ?? [:]
        activeDays = get("ActiveDays", [WorkoutDay].self) ?? WorkoutDay.allCases
        dayLabels = get("DayLabels", [WorkoutDay: String].self) ?? [:]
        sessionNotes = get("SessionNotes", [Date: String].self) ?? [:]
        notifications = get("AppNotifications", [AppNotification].self) ?? []
        notificationsEnabled = userDefaults.object(forKey: "NotificationsEnabled") as? Bool ?? true
        defaultRestDuration = userDefaults.object(forKey: "RestDuration") as? Int ?? 120

        // Los datos guardados antes del fin de semana solo traen lunes-viernes.
        for day in WorkoutDay.allCases where dailyWorkoutRecords[day] == nil {
            dailyWorkoutRecords[day] = []
        }

        if let saved = userDefaults.object(forKey: "LastSessionDate") as? Date {
            sessionDate = Calendar.current.startOfDay(for: saved)
        } else {
            // Primera vez con sesiones por fecha. Lo que hubiera marcado ya
            // está en el historial bajo el día en que se marcó; la plantilla
            // vuelve a cero para que la sesión de hoy empiece limpia.
            for day in WorkoutDay.allCases {
                dailyWorkoutRecords[day] = (dailyWorkoutRecords[day] ?? []).map { $0.resettingProgress() }
            }
            sessionDate = Calendar.current.startOfDay(for: Date())
            userDefaults.set(sessionDate, forKey: "LastSessionDate")
            scheduleSave()
        }
        userDefaults.set(true, forKey: "HasLaunchedBefore")
    }
}

extension WorkoutExercise {
    /// El mismo ejercicio en la plantilla, sin series hechas.
    func resettingProgress() -> WorkoutExercise {
        var r = self
        r.completedSets = 0
        r.setLogs = []
        r.lastSetCompletedAt = nil
        return r
    }
}
