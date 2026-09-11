//
//  WorkoutViewModel+Substitute.swift
//  ChamaFit
//
//  Cambiar un ejercicio por otro «solo hoy» o «para siempre». Lo de hoy se
//  deshace solo al archivar la sesión (cambio de día). Las series ya hechas
//  se quedan con el ejercicio que se hizo: si había series, el nuevo entra
//  justo detrás en vez de pisar el registro.
//

import Foundation

extension WorkoutViewModel {

    private struct SessionEdits: Codable {
        /// Registro → ejercicio original (se devuelve al archivar).
        var swaps: [UUID: UUID] = [:]
        /// Registros añadidos solo para hoy (se quitan al archivar).
        var extras: Set<UUID> = []
        /// Registros que salen de la plantilla al archivar (sustituidos para siempre con series hechas).
        var drops: Set<UUID> = []
        /// Bloques AMRAP/EMOM que se dieron por terminados hoy.
        var closedBlocks: Set<String> = []
        var isEmpty: Bool { swaps.isEmpty && extras.isEmpty && drops.isEmpty && closedBlocks.isEmpty }

        init() {}
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            swaps = (try? c.decodeIfPresent([UUID: UUID].self, forKey: .swaps)) ?? [:]
            extras = (try? c.decodeIfPresent(Set<UUID>.self, forKey: .extras)) ?? []
            drops = (try? c.decodeIfPresent(Set<UUID>.self, forKey: .drops)) ?? []
            closedBlocks = (try? c.decodeIfPresent(Set<String>.self, forKey: .closedBlocks)) ?? []
        }
    }

    /// Registro añadido solo para hoy (intervalos, movilidad): mañana no está.
    func markTodayOnly(_ recordId: UUID) {
        var e = sessionEdits
        e.extras.insert(recordId)
        sessionEdits = e
    }

    func markBlockClosed(_ day: WorkoutDay, _ group: Int) {
        var e = sessionEdits
        e.closedBlocks.insert(Self.blockKey(day, group))
        sessionEdits = e
    }

    func isBlockClosed(_ day: WorkoutDay, _ group: Int) -> Bool {
        sessionEdits.closedBlocks.contains(Self.blockKey(day, group))
    }

    private var sessionEdits: SessionEdits {
        get { userDefaults.data(forKey: "SessionEdits").flatMap { try? JSONDecoder().decode(SessionEdits.self, from: $0) } ?? SessionEdits() }
        set {
            if newValue.isEmpty { userDefaults.removeObject(forKey: "SessionEdits") }
            else if let d = try? JSONEncoder().encode(newValue) { userDefaults.set(d, forKey: "SessionEdits") }
        }
    }

    /// ¿Este registro está cambiado solo por hoy? Devuelve el ejercicio original.
    func temporarySwapOriginal(_ recordId: UUID) -> Exercise? {
        sessionEdits.swaps[recordId].flatMap(getExercise(by:))
    }

    /// Cambia el ejercicio de un registro de la sesión.
    func substitute(recordId: UUID, in day: WorkoutDay, with exercise: Exercise, forever: Bool) {
        ensureSession()
        guard var recs = dailyWorkoutRecords[day], let i = recs.firstIndex(where: { $0.id == recordId }) else { return }
        let original = recs[i].exerciseId
        guard original != exercise.id else { return }
        var edits = sessionEdits

        if recs[i].setLogs.isEmpty {
            // Sin series: se cambia el ejercicio del registro.
            recs[i].exerciseId = exercise.id
            if edits.swaps[recordId] == exercise.id {
                edits.swaps.removeValue(forKey: recordId)   // «Volver» al de siempre
            } else if forever {
                edits.swaps.removeValue(forKey: recordId)
            } else if edits.swaps[recordId] == nil {
                edits.swaps[recordId] = original
            }
            if recs[i].completedSets > 0 { recs[i].completedSets = 0 }
        } else {
            // Con series hechas: esas se quedan; el nuevo entra detrás.
            var added = WorkoutExercise(exerciseId: exercise.id)
            added.supersetGroup = recs[i].supersetGroup
            recs.insert(added, at: i + 1)
            if forever {
                edits.drops.insert(recordId)
                if let back = edits.swaps.removeValue(forKey: recordId) { _ = back }
            } else {
                edits.extras.insert(added.id)
            }
        }
        dailyWorkoutRecords[day] = recs
        sessionEdits = edits
        persistAll()
        publishSummary()
        PhoneConnectivity.shared.sendTodayContext()
    }

    /// Al archivar la sesión: vuelve la plantilla a como estaba salvo lo que
    /// se cambió para siempre. Lo llama `ensureSession` tras copiar al historial.
    func undoSessionEdits() {
        let edits = sessionEdits
        guard !edits.isEmpty else { return }
        for day in WorkoutDay.allCases {
            guard var recs = dailyWorkoutRecords[day] else { continue }
            recs.removeAll { edits.extras.contains($0.id) || edits.drops.contains($0.id) }
            for i in recs.indices {
                if let back = edits.swaps[recs[i].id] { recs[i].exerciseId = back }
            }
            dailyWorkoutRecords[day] = recs
        }
        sessionEdits = SessionEdits()
    }
}
