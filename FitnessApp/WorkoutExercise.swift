//
//  WorkoutExercise.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 18/7/25.
//

import Foundation

struct WorkoutExercise: Identifiable, Codable, Equatable {
    var id = UUID() // Este ID es ÚNICO para esta ocurrencia del ejercicio en un día específico
    var exerciseId: UUID // ID del Exercise base al que se refiere
    var completedSets: Int = 0
    var lastSetCompletedAt: Date?
    /// Registro real por serie (peso/reps ejecutados). Vacío en datos antiguos.
    var setLogs: [SetLog] = []
    /// Agrupación de superserie (mismo número = mismo grupo). nil = individual.
    var supersetGroup: Int? = nil
    /// Series previstas solo para hoy (hora límite, «hoy me cuesta»). nil = las
    /// del ejercicio; 0 = fuera de la sesión de hoy. Se borra al cambiar de día.
    var targetSets: Int? = nil

    /// Las series que tocan hoy en este registro.
    func planned(_ exercise: Exercise) -> Int { targetSets ?? exercise.totalSets }

    // isCompleted se calculará en el ViewModel usando el Exercise base

    init(id: UUID = UUID(), exerciseId: UUID, completedSets: Int = 0,
         lastSetCompletedAt: Date? = nil, setLogs: [SetLog] = [], supersetGroup: Int? = nil) {
        self.id = id
        self.exerciseId = exerciseId
        self.completedSets = completedSets
        self.lastSetCompletedAt = lastSetCompletedAt
        self.setLogs = setLogs
        self.supersetGroup = supersetGroup
    }

    enum CodingKeys: String, CodingKey {
        case id, exerciseId, completedSets, lastSetCompletedAt, setLogs, supersetGroup, targetSets
    }

    // Decode compatible: los datos guardados antes NO tienen setLogs/supersetGroup.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        exerciseId = try c.decode(UUID.self, forKey: .exerciseId)
        completedSets = try c.decodeIfPresent(Int.self, forKey: .completedSets) ?? 0
        lastSetCompletedAt = try c.decodeIfPresent(Date.self, forKey: .lastSetCompletedAt)
        setLogs = try c.decodeIfPresent([SetLog].self, forKey: .setLogs) ?? []
        supersetGroup = try c.decodeIfPresent(Int.self, forKey: .supersetGroup)
        targetSets = try? c.decodeIfPresent(Int.self, forKey: .targetSets)
    }
}
