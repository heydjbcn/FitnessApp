//
//  WorkoutViewModel+Blocks.swift
//  ChamaFit
//
//  Bloques: una superserie puede ser también circuito (descanso propio al
//  cerrar cada vuelta), AMRAP (tantas vueltas como puedas en N minutos) o
//  EMOM (cada minuto, el siguiente ejercicio del bloque).
//

import Foundation
import Combine

enum BlockKind: String, Codable, CaseIterable, Identifiable {
    case superset, circuit, amrap, emom
    var id: String { rawValue }

    var label: String {
        switch self {
        case .superset: return "Superserie"
        case .circuit: return "Circuito"
        case .amrap: return "AMRAP"
        case .emom: return "EMOM"
        }
    }

    var detail: String {
        switch self {
        case .superset: return "Alternas los ejercicios y descansas al cerrar la vuelta."
        case .circuit: return "Todos seguidos, sin pausa, y un descanso propio entre vueltas."
        case .amrap: return "Tantas vueltas como puedas en el tiempo que elijas."
        case .emom: return "Cada minuto empiezas el siguiente ejercicio; lo que sobra del minuto, descansas."
        }
    }

    /// Van con reloj propio en el modo entreno.
    var timed: Bool { self == .amrap || self == .emom }
}

struct BlockSettings: Codable, Equatable {
    var kind: BlockKind = .superset
    /// Circuito: descanso al cerrar la vuelta (segundos).
    var restBetweenRounds: Int = 90
    /// AMRAP: tiempo tope; EMOM: minutos totales.
    var minutes: Int = 10
}

extension WorkoutViewModel {

    private static let blocksKey = "Blocks"

    static func blockKey(_ day: WorkoutDay, _ group: Int) -> String { "\(day.rawValue)#\(group)" }

    /// Ajustes de los bloques de la rutina activa.
    var blockSettings: [String: BlockSettings] {
        get { userDefaults.data(forKey: Self.blocksKey).flatMap { try? JSONDecoder().decode([String: BlockSettings].self, from: $0) } ?? [:] }
        set {
            if newValue.isEmpty { userDefaults.removeObject(forKey: Self.blocksKey) }
            else if let d = try? JSONEncoder().encode(newValue) { userDefaults.set(d, forKey: Self.blocksKey) }
            objectWillChange.send()
        }
    }

    func block(_ day: WorkoutDay, _ group: Int) -> BlockSettings {
        blockSettings[Self.blockKey(day, group)] ?? BlockSettings()
    }

    func setBlock(_ settings: BlockSettings, _ day: WorkoutDay, _ group: Int) {
        var all = blockSettings
        all[Self.blockKey(day, group)] = settings.kind == .superset && settings == BlockSettings() ? nil : settings
        blockSettings = all
    }

    /// Los registros de un bloque, en su orden.
    func blockMembers(_ day: WorkoutDay, _ group: Int) -> [WorkoutExercise] {
        (dailyWorkoutRecords[day] ?? []).filter { $0.supersetGroup == group }
    }

    /// AMRAP: una vuelta completa = una serie más en cada ejercicio del bloque.
    func logRound(_ day: WorkoutDay, _ group: Int, now: Date = Date()) {
        ensureSession()
        guard var recs = dailyWorkoutRecords[day] else { return }
        for i in recs.indices where recs[i].supersetGroup == group {
            guard let ex = getExercise(by: recs[i].exerciseId) else { continue }
            let s = proposedSet(for: ex, record: recs[i])
            recs[i].setLogs.append(SetLog(reps: ex.segundos > 0 ? ex.segundos : s.reps, weight: s.weight, date: now))
            recs[i].completedSets = recs[i].setLogs.count
            recs[i].lastSetCompletedAt = now
        }
        dailyWorkoutRecords[day] = recs
        recordHistory(for: day)
        HapticManager.shared.setCompleted()
    }

    /// EMOM: una serie del ejercicio de ese minuto (aunque pase de las previstas).
    func logBlockSet(_ recordId: UUID, in day: WorkoutDay, now: Date = Date()) {
        ensureSession()
        guard let i = dailyWorkoutRecords[day]?.firstIndex(where: { $0.id == recordId }),
              let ex = getExercise(by: dailyWorkoutRecords[day]![i].exerciseId) else { return }
        var r = dailyWorkoutRecords[day]![i]
        let s = proposedSet(for: ex, record: r)
        r.setLogs.append(SetLog(reps: ex.segundos > 0 ? ex.segundos : s.reps, weight: s.weight, date: now))
        r.completedSets = r.setLogs.count
        r.lastSetCompletedAt = now
        dailyWorkoutRecords[day]![i] = r
        recordHistory(for: day)
        HapticManager.shared.setCompleted()
    }

    /// Al acabar un AMRAP/EMOM: el bloque queda cerrado por hoy aunque haya
    /// menos vueltas de las previstas (las series son las que se hicieron).
    func closeBlock(_ day: WorkoutDay, _ group: Int) {
        markBlockClosed(day, group)
        recordHistory(for: day)
        objectWillChange.send()
    }

    /// Fases del reloj para un AMRAP o un EMOM.
    func blockPhases(_ day: WorkoutDay, _ group: Int) -> [IntervalEngine.Phase] {
        let s = block(day, group)
        let names = blockMembers(day, group).compactMap { getExercise(by: $0.exerciseId)?.name }
        switch s.kind {
        case .amrap:
            return [IntervalEngine.Phase(name: "AMRAP", seconds: s.minutes * 60, kind: .work)]
        case .emom:
            guard !names.isEmpty else { return [] }
            return (0..<s.minutes).map { m in
                IntervalEngine.Phase(name: names[m % names.count], seconds: 60, kind: .work)
            }
        default:
            return []
        }
    }
}
