//
//  Backup.swift
//  ChamaFit
//
//  Copia de seguridad completa en JSON (exportar / restaurar) y exportación
//  CSV, ambas como ficheros que se generan solo al compartir. Sin iCloud, es
//  la forma de cambiar de móvil o de pasarle la app a otra persona.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

/// Todo lo que hay que llevarse para reconstruir la app en otro iPhone.
struct ChamaFitBackup: Codable {
    var version = 1
    var exportedAt = Date()
    var exercises: [Exercise]
    var plan: [WorkoutDay: [WorkoutExercise]]
    var history: [Date: [WorkoutDay: [WorkoutExercise]]]
    var bodyWeight: [Date: Double]
    var activeDays: [WorkoutDay]
    var dayLabels: [WorkoutDay: String]
    var notes: [Date: String]
    var profile: [String: String]
    /// Rutinas guardadas y nombre de la activa (opcionales: copias antiguas no los traen).
    var routines: [Routine]? = nil
    var activeRoutineName: String? = nil

    init(exercises: [Exercise], plan: [WorkoutDay: [WorkoutExercise]],
         history: [Date: [WorkoutDay: [WorkoutExercise]]], bodyWeight: [Date: Double],
         activeDays: [WorkoutDay], dayLabels: [WorkoutDay: String], notes: [Date: String],
         profile: [String: String], routines: [Routine]? = nil, activeRoutineName: String? = nil) {
        self.exercises = exercises; self.plan = plan; self.history = history
        self.bodyWeight = bodyWeight; self.activeDays = activeDays; self.dayLabels = dayLabels
        self.notes = notes; self.profile = profile
        self.routines = routines; self.activeRoutineName = activeRoutineName
    }

    /// Solo `exercises` es imprescindible: una copia a la que le falte cualquier
    /// otra clave se restaura con lo que traiga.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        exportedAt = try c.decodeIfPresent(Date.self, forKey: .exportedAt) ?? Date()
        exercises = try c.decode([Exercise].self, forKey: .exercises)
        plan = try c.decodeIfPresent([WorkoutDay: [WorkoutExercise]].self, forKey: .plan) ?? [:]
        history = try c.decodeIfPresent([Date: [WorkoutDay: [WorkoutExercise]]].self, forKey: .history) ?? [:]
        bodyWeight = try c.decodeIfPresent([Date: Double].self, forKey: .bodyWeight) ?? [:]
        activeDays = try c.decodeIfPresent([WorkoutDay].self, forKey: .activeDays) ?? WorkoutDay.allCases
        dayLabels = try c.decodeIfPresent([WorkoutDay: String].self, forKey: .dayLabels) ?? [:]
        notes = try c.decodeIfPresent([Date: String].self, forKey: .notes) ?? [:]
        profile = try c.decodeIfPresent([String: String].self, forKey: .profile) ?? [:]
        routines = try c.decodeIfPresent([Routine].self, forKey: .routines)
        activeRoutineName = try c.decodeIfPresent(String.self, forKey: .activeRoutineName)
    }
}

extension WorkoutViewModel {

    private static let profileKeys = ["user_name", "user_age", "user_height", "user_weight"]

    func makeBackup() -> ChamaFitBackup {
        var profile: [String: String] = [:]
        for key in Self.profileKeys {
            if let v = userDefaults.string(forKey: key), !v.isEmpty { profile[key] = v }
        }
        return ChamaFitBackup(exercises: availableExercises, plan: dailyWorkoutRecords,
                              history: workoutHistory, bodyWeight: bodyWeightHistory,
                              activeDays: activeDays, dayLabels: dayLabels,
                              notes: sessionNotes, profile: profile,
                              routines: savedRoutines, activeRoutineName: activeRoutineName)
    }

    func backupData() throws -> Data {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.sortedKeys]
        return try enc.encode(makeBackup())
    }

    enum RestoreError: LocalizedError {
        case unreadable, newerVersion(Int)
        var errorDescription: String? {
            switch self {
            case .unreadable: return "El fichero no es una copia de ChamaFit."
            case .newerVersion(let v): return "La copia es de una versión más nueva de la app (formato \(v))."
            }
        }
    }

    /// Sustituye TODO por el contenido de la copia. La sesión de hoy se
    /// reconstruye desde la plantilla que traiga el fichero.
    func restore(from data: Data) throws {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        guard let backup = try? dec.decode(ChamaFitBackup.self, from: data) else { throw RestoreError.unreadable }
        guard backup.version <= 1 else { throw RestoreError.newerVersion(backup.version) }

        availableExercises = backup.exercises
        dailyWorkoutRecords = backup.plan
        for day in WorkoutDay.allCases where dailyWorkoutRecords[day] == nil { dailyWorkoutRecords[day] = [] }
        workoutHistory = backup.history
        bodyWeightHistory = backup.bodyWeight
        activeDays = backup.activeDays
        dayLabels = backup.dayLabels
        sessionNotes = backup.notes
        for (key, value) in backup.profile where Self.profileKeys.contains(key) {
            userDefaults.set(value, forKey: key)
        }
        savedRoutines = backup.routines ?? []
        activeRoutineName = backup.activeRoutineName ?? "Mi rutina"
        stopTimer(silent: true)
        prCelebration = nil
        // Las series que traiga la plantilla pertenecen al día en que se hizo la
        // copia: si es de otro día, `ensureSession` las archiva bajo esa fecha.
        adoptSession(date: backup.exportedAt)
        saveNow()
        ensureSession()
        publishSummary()
        PhoneConnectivity.shared.sendTodayContext()
        HapticManager.shared.success()
    }
}

// MARK: - Ficheros para compartir

/// El JSON de la copia. Se genera en el momento de compartir, no al pintar la pantalla.
struct BackupFile: Transferable, Sendable {
    let make: @MainActor () throws -> Data

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { file in
            let data = try await file.make()
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("ChamaFit-copia-\(Self.stamp()).json")
            try data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }

    static func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

/// El CSV con una fila por serie.
struct CSVFile: Transferable, Sendable {
    let make: @MainActor () -> String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            let csv = await file.make()
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("ChamaFit-entrenamientos-\(BackupFile.stamp()).csv")
            try Data(csv.utf8).write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}
