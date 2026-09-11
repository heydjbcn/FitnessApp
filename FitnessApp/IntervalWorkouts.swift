//
//  IntervalWorkouts.swift
//  ChamaFit
//
//  Intervalos (Tabata, 30/30, EMOM, a medida) y rutinas de movilidad por
//  tiempo. Las dos cosas son una lista de fases para el mismo reloj; al
//  terminar se apuntan en la sesión de hoy (cuentan en el historial y la
//  racha) y el HIIT se guarda en Salud.
//

import Foundation
import Combine
import HealthKit

struct IntervalPlan: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var warmup: Int = 0
    var work: Int
    var rest: Int
    var rounds: Int
    var blocks: Int = 1
    var blockRest: Int = 60
    var cooldown: Int = 0
    /// Nombres opcionales por vuelta (ejercicios que se van rotando).
    var moves: [String] = []

    var workSeconds: Int { work * rounds * blocks }
    var totalSeconds: Int {
        warmup + cooldown + blocks * (rounds * (work + rest) - rest) + max(0, blocks - 1) * blockRest
    }

    var phases: [IntervalEngine.Phase] {
        var out: [IntervalEngine.Phase] = []
        if warmup > 0 { out.append(.init(name: "Calentamiento", seconds: warmup, kind: .warmup)) }
        for b in 0..<max(1, blocks) {
            for r in 0..<max(1, rounds) {
                let move = moves.isEmpty ? "Trabajo" : moves[(b * rounds + r) % moves.count]
                out.append(.init(name: move, seconds: work, kind: .work))
                if r < rounds - 1 && rest > 0 { out.append(.init(name: "Descanso", seconds: rest, kind: .rest)) }
            }
            if b < blocks - 1 && blockRest > 0 { out.append(.init(name: "Descanso entre bloques", seconds: blockRest, kind: .rest)) }
        }
        if cooldown > 0 { out.append(.init(name: "Vuelta a la calma", seconds: cooldown, kind: .cooldown)) }
        return out
    }

    static let presets: [IntervalPlan] = [
        IntervalPlan(name: "Tabata", warmup: 120, work: 20, rest: 10, rounds: 8, cooldown: 60,
                     moves: ["Burpees", "Escaladores", "Sentadilla sin peso", "Jumping jacks"]),
        IntervalPlan(name: "30/30", warmup: 180, work: 30, rest: 30, rounds: 10, cooldown: 120),
        IntervalPlan(name: "EMOM 12", work: 45, rest: 15, rounds: 12,
                     moves: ["Swing con kettlebell", "Flexiones", "Sentadilla goblet"]),
        IntervalPlan(name: "Sprints 40/20 × 3", warmup: 300, work: 40, rest: 20, rounds: 6, blocks: 3, blockRest: 120, cooldown: 180),
    ]
}

struct MobilityRoutine: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    /// Ejercicio del catálogo y segundos (por lado ya incluidos).
    var items: [Item]
    struct Item: Codable, Equatable, Hashable { var name: String; var seconds: Int }

    var totalSeconds: Int { items.reduce(0) { $0 + $1.seconds } + max(0, items.count - 1) * 5 }

    var phases: [IntervalEngine.Phase] {
        var out: [IntervalEngine.Phase] = []
        for (i, it) in items.enumerated() {
            out.append(.init(name: it.name, seconds: it.seconds, kind: .work))
            if i < items.count - 1 { out.append(.init(name: "Cambia", seconds: 5, kind: .rest)) }
        }
        return out
    }

    static let generalId = UUID(uuidString: "00000000-0000-0000-0000-00000000B0B1")!
    static let presets: [MobilityRoutine] = [
        MobilityRoutine(id: generalId, name: "Movilidad general", items: [
            .init(name: "Gato-camello", seconds: 45), .init(name: "Rotaciones torácicas", seconds: 60),
            .init(name: "Movilidad de cadera 90/90", seconds: 90), .init(name: "Movilidad de tobillo", seconds: 60),
            .init(name: "Dislocaciones de hombro con banda", seconds: 45), .init(name: "Estiramiento de isquiotibiales", seconds: 60)]),
        MobilityRoutine(id: UUID(uuidString: "00000000-0000-0000-0000-00000000B0B2")!, name: "Antes de pierna", items: [
            .init(name: "Movilidad de tobillo", seconds: 60), .init(name: "Movilidad de cadera 90/90", seconds: 90),
            .init(name: "Sentadilla sin peso", seconds: 45), .init(name: "Puente de glúteo", seconds: 45)]),
        MobilityRoutine(id: UUID(uuidString: "00000000-0000-0000-0000-00000000B0B3")!, name: "Antes de torso", items: [
            .init(name: "Dislocaciones de hombro con banda", seconds: 45), .init(name: "Rotaciones torácicas", seconds: 60),
            .init(name: "Gato-camello", seconds: 45), .init(name: "Face pull", seconds: 45)]),
    ]
}

extension WorkoutViewModel {

    // MARK: - Guardadas

    var savedIntervalPlans: [IntervalPlan] {
        get { userDefaults.data(forKey: "IntervalPlans").flatMap { try? JSONDecoder().decode([IntervalPlan].self, from: $0) } ?? [] }
        set { if let d = try? JSONEncoder().encode(newValue) { userDefaults.set(d, forKey: "IntervalPlans") }; objectWillChange.send() }
    }

    var mobilityRoutines: [MobilityRoutine] {
        get {
            let mine = userDefaults.data(forKey: "MobilityRoutines").flatMap { try? JSONDecoder().decode([MobilityRoutine].self, from: $0) } ?? []
            let ids = Set(mine.map(\.id))
            return MobilityRoutine.presets.filter { !ids.contains($0.id) } + mine
        }
        set { if let d = try? JSONEncoder().encode(newValue) { userDefaults.set(d, forKey: "MobilityRoutines") }; objectWillChange.send() }
    }

    /// Calentamiento enganchado a una sesión (se ofrece al empezar el modo entreno).
    func warmupLink(_ day: WorkoutDay) -> MobilityRoutine? {
        let links = (userDefaults.dictionary(forKey: "WarmupLinks") as? [String: String]) ?? [:]
        guard let raw = links[day.rawValue], let id = UUID(uuidString: raw) else { return nil }
        return mobilityRoutines.first { $0.id == id }
    }

    func setWarmupLink(_ routine: MobilityRoutine?, for day: WorkoutDay) {
        var links = (userDefaults.dictionary(forKey: "WarmupLinks") as? [String: String]) ?? [:]
        links[day.rawValue] = routine?.id.uuidString
        userDefaults.set(links, forKey: "WarmupLinks")
        objectWillChange.send()
    }

    // MARK: - Apuntar lo hecho

    /// Un ejercicio de la biblioteca para apuntar intervalos o movilidad («Intervalos · Tabata»).
    private func timedExercise(named name: String, group: String, icon: String) -> Exercise {
        if let e = availableExercises.first(where: { $0.name == name }) { return e }
        let e = Exercise(name: name, repetitions: 0, weight: 0, totalSets: 1, restDuration: 0,
                         sfSymbolIcon: icon, iconColor: "accent", segundos: 30, muscleGroup: group)
        availableExercises.append(e)
        return e
    }

    /// Mete lo hecho en la sesión de hoy como registro «solo hoy»: cuenta para
    /// historial, racha y semana, y mañana no queda en la plantilla.
    func logTimedSession(name: String, group: String, icon: String, workIntervals: [Int], start: Date, end: Date) {
        guard !workIntervals.isEmpty else { return }
        ensureSession()
        let ex = timedExercise(named: name, group: group, icon: icon)
        let day = trainingDay
        let step = end.timeIntervalSince(start) / Double(workIntervals.count)
        var rec = WorkoutExercise(exerciseId: ex.id)
        rec.setLogs = workIntervals.enumerated().map { i, s in SetLog(reps: s, weight: 0, date: start.addingTimeInterval(step * Double(i + 1))) }
        rec.completedSets = rec.setLogs.count
        rec.targetSets = rec.setLogs.count
        rec.lastSetCompletedAt = end
        dailyWorkoutRecords[day, default: []].append(rec)
        markTodayOnly(rec.id)
        recordHistory(for: day)
        persistAll()
        publishSummary()
    }

    func logHIIT(_ plan: IntervalPlan, completedWork: [Int], start: Date, end: Date) {
        logTimedSession(name: String(localized: "Intervalos · \(plan.name)"), group: "Cardio", icon: "figure.highintensity.intervaltraining",
                        workIntervals: completedWork, start: start, end: end)
        Task { await HealthManager.shared.saveWorkout(start: start, end: end, type: .highIntensityIntervalTraining) }
    }

    func logMobility(_ r: MobilityRoutine, completed: [Int], start: Date, end: Date) {
        logTimedSession(name: String(localized: "Movilidad · \(r.name)"), group: "Movilidad", icon: "figure.flexibility",
                        workIntervals: completed, start: start, end: end)
    }

    // MARK: - Live Activity del reloj de fases

    func showPhaseActivity(end: Date, label: String, session: String) {
        guard !AppDefaults.isTesting else { return }
        liveActivity.reattach(endDate: end, label: label, sessionName: session, style: activityStyle)
    }

    func endPhaseActivity() {
        guard !AppDefaults.isTesting, !timerActive else { return }
        liveActivity.end()
    }
}
