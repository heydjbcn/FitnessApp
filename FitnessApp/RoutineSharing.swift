//
//  RoutineSharing.swift
//  ChamaFit
//
//  Compartir una rutina con la gente del gimnasio: un fichero .chamafit
//  (JSON) que lleva los ejercicios completos, porque en el otro iPhone no
//  existen. Se manda por AirDrop o WhatsApp y, al abrirlo, ChamaFit enseña
//  la rutina y la añade como rutina nueva.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

extension UTType {
    static let chamafitRoutine = UTType(exportedAs: "mauri.chamafit.routine", conformingTo: .json)
}

struct SharedRoutine: Codable, Equatable {
    struct Item: Codable, Equatable {
        var name: String
        var repetitions: Int
        var weight: Double
        var totalSets: Int
        var restDuration: Int
        var segundos: Int
        var rir: Int
        var muscleGroup: String?
        var icon: String?
        var setupNote: String?
        var supersetGroup: Int?
    }
    var version = 1
    var name: String
    var author: String?
    var labels: [String: String]          // "Lunes": "Pecho y tríceps"
    var days: [String: [Item]]            // "Lunes": [...]

    var exerciseCount: Int { Set(days.values.flatMap { $0 }.map(\.name)).count }
    var summary: String { String(localized: "\(days.filter { !$0.value.isEmpty }.count) días · \(exerciseCount) ejercicios") }
}

/// El fichero que sale por la hoja de compartir.
struct RoutineFile: Transferable, Sendable {
    let make: @MainActor () throws -> (name: String, data: Data)

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .chamafitRoutine) { file in
            let (name, data) = try await file.make()
            let safe = name.replacingOccurrences(of: "/", with: "-")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(String(localized: "Rutina \(safe).chamafit"))
            try data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

extension WorkoutViewModel {

    /// La rutina activa lista para mandar (sin progreso ni historial).
    func shareableRoutine(author: String?) -> SharedRoutine {
        var days: [String: [SharedRoutine.Item]] = [:]
        var labels: [String: String] = [:]
        for day in WorkoutDay.allCases {
            let items = (dailyWorkoutRecords[day] ?? []).compactMap { rec -> SharedRoutine.Item? in
                guard let ex = getExercise(by: rec.exerciseId) else { return nil }
                return .init(name: ex.name, repetitions: ex.repetitions, weight: ex.weight, totalSets: ex.totalSets,
                             restDuration: ex.restDuration, segundos: ex.segundos, rir: ex.rir, muscleGroup: ex.muscleGroup,
                             icon: ex.sfSymbolIcon, setupNote: nil, supersetGroup: rec.supersetGroup)
            }
            if !items.isEmpty { days[day.rawValue] = items }
            if let l = label(for: day) { labels[day.rawValue] = l }
        }
        let clean = author?.trimmingCharacters(in: .whitespaces)
        return SharedRoutine(name: activeRoutineName, author: (clean?.isEmpty ?? true) ? nil : clean, labels: labels, days: days)
    }

    func routineFileData(author: String?) throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try enc.encode(shareableRoutine(author: author))
    }

    static func readSharedRoutine(from data: Data) throws -> SharedRoutine {
        guard let r = try? JSONDecoder().decode(SharedRoutine.self, from: data) else { throw RestoreError.unreadable }
        guard r.version <= 1 else { throw RestoreError.newerVersion(r.version) }
        return r
    }

    /// Añade la rutina recibida como rutina nueva (la actual queda guardada).
    /// Enlaza los ejercicios que ya tengas con el mismo nombre; crea los demás.
    @discardableResult
    func importSharedRoutine(_ r: SharedRoutine) -> Int {
        let existingNames = Set(savedRoutines.map(\.name) + [activeRoutineName])
        var name = r.name.trimmingCharacters(in: .whitespaces).isEmpty ? "Rutina compartida" : r.name
        if existingNames.contains(name) { name += r.author.map { " (\($0))" } ?? " (compartida)" }
        createRoutine(named: name, copyingCurrent: false)
        var added = 0
        for day in WorkoutDay.allCases {
            if let l = r.labels[day.rawValue] { setLabel(l, for: day) }
            for item in r.days[day.rawValue] ?? [] {
                let ex: Exercise
                if let found = availableExercises.first(where: { $0.name.caseInsensitiveCompare(item.name) == .orderedSame }) {
                    ex = found
                } else {
                    ex = Exercise(name: item.name, repetitions: item.repetitions, weight: item.weight,
                                  totalSets: min(12, max(1, item.totalSets)), restDuration: min(600, max(0, item.restDuration)),
                                  sfSymbolIcon: item.icon, iconColor: "accent", segundos: item.segundos, rir: item.rir,
                                  muscleGroup: item.muscleGroup)
                    availableExercises.append(ex)
                }
                dailyWorkoutRecords[day, default: []].append(WorkoutExercise(exerciseId: ex.id, supersetGroup: item.supersetGroup))
                added += 1
            }
        }
        activeDays = WorkoutDay.allCases.filter { !(dailyWorkoutRecords[$0] ?? []).isEmpty }
        persistAll()
        publishSummary()
        return added
    }
}
