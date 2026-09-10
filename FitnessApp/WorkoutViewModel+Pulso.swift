//
//  WorkoutViewModel+Pulso.swift
//  FitnessApp
//
//  Lo que el rediseño «Pulso» necesita del modelo y no existía: días de un
//  ejercicio sin perder progreso, notas por sesión, borrar un día del
//  historial, centro de avisos y rutina de ejemplo.
//

import Foundation

// MARK: - Aviso del centro de notificaciones

struct AppNotification: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case workoutReminder, restTimer, achievement, general
    }

    var id: UUID = UUID()
    var kind: Kind
    var title: String
    var message: String
    var date: Date = Date()
    var read: Bool = false
}

extension WorkoutViewModel {

    // MARK: - Formato

    /// "82,5 kg" / "80 kg", como lo escribe el prototipo.
    static func kg(_ value: Double) -> String {
        let text = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
        return "\(text) kg"
    }

    /// "2:00" / "45 s"
    static func restText(_ seconds: Int) -> String {
        seconds >= 60 ? String(format: "%d:%02d", seconds / 60, seconds % 60) : "\(seconds) s"
    }

    /// Línea de datos de un ejercicio: "4 series · 8 reps · 80 kg · RIR 2".
    func meta(for exercise: Exercise) -> String {
        var parts = ["\(exercise.totalSets) series"]
        if exercise.segundos > 0 {
            parts.append("\(exercise.segundos) s")
        } else if exercise.repetitions > 0 {
            parts.append("\(exercise.repetitions) reps")
        }
        if exercise.weight > 0 { parts.append(Self.kg(exercise.weight)) }
        if exercise.rir > 0 { parts.append("RIR \(exercise.rir)") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Días de un ejercicio

    /// Días en los que está programado un ejercicio, en orden de semana.
    func days(for exerciseId: UUID) -> [WorkoutDay] {
        WorkoutDay.allCases
            .filter { (dailyWorkoutRecords[$0] ?? []).contains { $0.exerciseId == exerciseId } }
            .sorted { $0.weekOrder < $1.weekOrder }
    }

    /// Deja el ejercicio exactamente en `newDays`. A diferencia de
    /// `reassignExercise`, NO toca los días en los que ya estaba: si ya llevabas
    /// series hechas ese día, se conservan.
    func setDays(_ newDays: Set<WorkoutDay>, for exerciseId: UUID) {
        for day in WorkoutDay.allCases {
            let has = (dailyWorkoutRecords[day] ?? []).contains { $0.exerciseId == exerciseId }
            let wants = newDays.contains(day)
            if wants && !has {
                dailyWorkoutRecords[day, default: []].append(WorkoutExercise(exerciseId: exerciseId))
            } else if !wants && has {
                dailyWorkoutRecords[day]?.removeAll { $0.exerciseId == exerciseId }
            }
        }
        // Un día que recibe ejercicios pasa a ser día de entrenamiento.
        for day in newDays where !activeDays.contains(day) {
            activeDays.append(day)
        }
        activeDays.sort { $0.weekOrder < $1.weekOrder }
        persistAll()
    }

    /// Da de alta un ejercicio ya montado por el asistente y lo programa en sus días.
    func createExercise(_ exercise: Exercise, days: Set<WorkoutDay>) {
        availableExercises.append(exercise)
        setDays(days, for: exercise.id)
        HapticManager.shared.exerciseAdded()
    }

    // MARK: - Notas de sesión

    func note(for date: Date) -> String? {
        let text = sessionNotes[Calendar.current.startOfDay(for: date)]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (text?.isEmpty ?? true) ? nil : text
    }

    func setNote(_ text: String, for date: Date) {
        let key = Calendar.current.startOfDay(for: date)
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty { sessionNotes.removeValue(forKey: key) } else { sessionNotes[key] = clean }
    }

    // MARK: - Historial

    /// Ejercicios registrados en una fecha, con el día de rutina al que pertenecían.
    func historyItems(for date: Date) -> [(day: WorkoutDay, record: WorkoutExercise, exercise: Exercise)] {
        guard let byDay = exercisesForDate(date) else { return [] }
        var items: [(WorkoutDay, WorkoutExercise, Exercise)] = []
        for day in byDay.keys.sorted(by: { $0.weekOrder < $1.weekOrder }) {
            for record in byDay[day] ?? [] where record.completedSets > 0 {
                if let exercise = getExercise(by: record.exerciseId) {
                    items.append((day, record, exercise))
                }
            }
        }
        return items
    }

    /// Borra todo lo de un día: registro, peso y nota. Si es hoy, además
    /// deja a cero las series del día que se entrenó.
    func deleteHistory(for date: Date) {
        let key = Calendar.current.startOfDay(for: date)
        let trainedDays = Array((workoutHistory[key] ?? [:]).keys)
        workoutHistory.removeValue(forKey: key)
        bodyWeightHistory.removeValue(forKey: key)
        sessionNotes.removeValue(forKey: key)
        if Calendar.current.isDateInToday(date) {
            for day in trainedDays {
                dailyWorkoutRecords[day] = (dailyWorkoutRecords[day] ?? []).map {
                    var r = $0
                    r.completedSets = 0
                    r.setLogs = []
                    r.lastSetCompletedAt = nil
                    return r
                }
            }
        }
        HapticManager.shared.destructiveAction()
        persistAll()
    }

    /// Minutos entrenados esta semana (3 min por serie hecha, como el prototipo).
    func weeklyTrainedMinutes() -> Int {
        let calendar = Calendar.current
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        let sets = workoutHistory
            .filter { week.contains($0.key) }
            .flatMap { $0.value.values.flatMap { $0 } }
            .reduce(0) { $0 + $1.completedSets }
        return sets * 3
    }

    /// Los cinco mejores pesos registrados, uno por ejercicio.
    func topRecords(limit: Int = 5) -> [(exercise: Exercise, weight: Double)] {
        availableExercises
            .compactMap { ex in personalRecord(for: ex.id).map { (ex, $0.weight) } }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { (exercise: $0.0, weight: $0.1) }
    }

    // MARK: - Centro de avisos

    var unreadNotifications: Int { notifications.filter { !$0.read }.count }

    func notify(_ kind: AppNotification.Kind, title: String, message: String) {
        guard notificationsEnabled else { return }
        notifications.insert(AppNotification(kind: kind, title: title, message: message), at: 0)
        if notifications.count > 60 { notifications.removeLast(notifications.count - 60) }
    }

    func markNotificationRead(_ id: UUID) {
        guard let i = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[i].read = true
    }

    func markAllNotificationsRead() {
        notifications = notifications.map { var n = $0; n.read = true; return n }
    }

    func clearNotifications() { notifications = [] }

    // MARK: - Rutina de ejemplo

    /// Carga los ejercicios y la rutina de ejemplo, sin inventar historial.
    func loadSampleRoutine() {
        let exercises = createDefaultExercises()
        availableExercises.append(contentsOf: exercises)
        setupDefaultWorkoutPlan(exercises: exercises)
        for day in WorkoutDay.allCases where dailyWorkoutRecords[day] == nil {
            dailyWorkoutRecords[day] = []
        }
        activeDays = WorkoutDay.allCases.filter { !(dailyWorkoutRecords[$0] ?? []).isEmpty }
        HapticManager.shared.success()
        persistAll()
    }
}
