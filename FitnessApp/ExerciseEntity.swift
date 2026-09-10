//
//  ExerciseEntity.swift
//  ChamaFit
//
//  Los ejercicios de la biblioteca en Spotlight y en Atajos: buscar
//  «press banca» en el iPhone abre su ficha en ChamaFit.
//

import AppIntents
import CoreSpotlight

struct ExerciseEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Ejercicio"
    static let defaultQuery = ExerciseQuery()

    let id: UUID
    let name: String
    let group: String?
    let meta: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(group.map { "\($0) · " } ?? "")\(meta)",
                              image: .init(systemName: "dumbbell.fill"))
    }

    @MainActor init(_ ex: Exercise, vm: WorkoutViewModel) {
        id = ex.id
        name = ex.name
        group = ex.muscleGroup
        meta = vm.meta(for: ex)
    }
}

struct ExerciseQuery: EntityStringQuery {
    @MainActor func entities(for identifiers: [UUID]) async throws -> [ExerciseEntity] {
        let vm = WorkoutViewModel.shared
        return identifiers.compactMap { id in vm.getExercise(by: id).map { ExerciseEntity($0, vm: vm) } }
    }

    @MainActor func entities(matching string: String) async throws -> [ExerciseEntity] {
        let vm = WorkoutViewModel.shared
        let q = string.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return vm.availableExercises
            .filter { $0.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).contains(q) }
            .map { ExerciseEntity($0, vm: vm) }
    }

    @MainActor func suggestedEntities() async throws -> [ExerciseEntity] {
        let vm = WorkoutViewModel.shared
        return vm.availableExercises.map { ExerciseEntity($0, vm: vm) }
    }
}

struct OpenExerciseIntent: OpenIntent {
    static let title: LocalizedStringResource = "Abrir ejercicio"
    static let description = IntentDescription("Abre la ficha de un ejercicio en ChamaFit.")
    @Parameter(title: "Ejercicio") var target: ExerciseEntity
    init() {}
    func perform() async throws -> some IntentResult {
        await MainActor.run { WorkoutViewModel.shared.pendingExerciseOpen = target.id }
        return .result()
    }
}

extension WorkoutViewModel {
    /// Vuelve a indexar la biblioteca en Spotlight (al arrancar y al cambiarla).
    func indexExercisesForSpotlight() {
        guard !AppDefaults.isTesting else { return }
        let entities = availableExercises.map { ExerciseEntity($0, vm: self) }
        Task {
            try? await CSSearchableIndex.default().deleteAppEntities(ofType: ExerciseEntity.self)
            try? await CSSearchableIndex.default().indexAppEntities(entities)
        }
    }
}
