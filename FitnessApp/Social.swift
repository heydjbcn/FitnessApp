//
//  Social.swift
//  ChamaFit
//
//  Amigos y retos por iCloud (base de datos pública de CloudKit). Cada uno
//  publica solo un resumen (sesiones, series y tonelaje de la semana, racha
//  y récords, según lo que elija compartir). Amigos por código; retos con
//  marcador que se actualiza al abrir, e invitación por enlace
//  chamafit://reto/<id>. Nada del historial detallado sale del iPhone.
//
//  Necesita el permiso de iCloud › CloudKit en Xcode (contenedor
//  iCloud.Mauri.FitnessApp) y el esquema publicado; mientras tanto, la clave
//  ChamaFitCloudKit del Info.plist está en NO y todo esto queda apagado.
//

import Foundation
import Combine
import CloudKit

enum ChallengeMetric: String, Codable, CaseIterable, Identifiable {
    case sessions, sets, volume, streak
    var id: String { rawValue }
    var label: String {
        switch self {
        case .sessions: return "Sesiones"
        case .sets: return "Series"
        case .volume: return "Tonelaje"
        case .streak: return "Racha"
        }
    }
}

struct FriendSummary: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var code: String
    var weekSessions: Int?
    var weekSets: Int?
    var weekVolume: Double?
    var streak: Int?
    var records: [String]?
    var updatedAt: Date
}

struct Challenge: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var metric: ChallengeMetric
    var start: Date
    var end: Date
    var creator: String
    var link: URL { URL(string: "chamafit://reto/\(id)")! }
}

struct ChallengeScore: Equatable, Identifiable {
    var id: String { profileId }
    var profileId: String
    var name: String
    var score: Double
}

/// Qué comparte cada uno.
struct SharePrefs: Codable, Equatable {
    var sessions = true
    var volume = true
    var streak = true
    var records = false
}

extension WorkoutViewModel {

    /// Puntuación propia en un reto (de tu historial entre las dos fechas).
    func challengeScore(_ metric: ChallengeMetric, from start: Date, to end: Date, now: Date = Date()) -> Double {
        let cal = Calendar.current
        let s = cal.startOfDay(for: start)
        let limit = min(end, now)
        let entries = workoutHistory.filter { $0.key >= s && $0.key <= limit }
        let records = entries.values.flatMap { $0.values.flatMap { $0 } }.filter { $0.completedSets > 0 }
        switch metric {
        case .sessions: return Double(entries.values.filter { $0.values.contains { $0.contains { $0.completedSets > 0 } } }.count)
        case .sets: return Double(records.reduce(0) { $0 + $1.completedSets })
        case .volume: return volume(of: records)
        case .streak:
            // Racha más larga dentro del reto (días seguidos con entreno).
            var best = 0, run = 0
            var d = s
            while d <= limit {
                if hasWorkoutForDate(d) { run += 1; best = max(best, run) } else { run = 0 }
                guard let n = cal.date(byAdding: .day, value: 1, to: d) else { break }
                d = n
            }
            return Double(best)
        }
    }
}

@MainActor
final class Social: ObservableObject {
    static let shared = Social()

    static let containerId = "iCloud.Mauri.FitnessApp"

    /// Solo si el binario lleva el permiso (sin él, CKContainer cierra la app).
    static var available: Bool {
        !AppDefaults.isTesting && (Bundle.main.object(forInfoDictionaryKey: "ChamaFitCloudKit") as? Bool ?? false)
    }

    let defaults: UserDefaults
    @Published private(set) var friends: [FriendSummary] = []
    @Published private(set) var challenges: [Challenge] = []
    @Published private(set) var boards: [String: [ChallengeScore]] = [:]
    @Published var problem: String? = nil
    @Published private(set) var busy = false

    init(defaults: UserDefaults = AppDefaults.store) {
        self.defaults = defaults
        friends = (defaults.data(forKey: "SocialFriendsCache").flatMap { try? JSONDecoder().decode([FriendSummary].self, from: $0) }) ?? []
        challenges = (defaults.data(forKey: "SocialChallenges").flatMap { try? JSONDecoder().decode([Challenge].self, from: $0) }) ?? []
    }

    // MARK: - Identidad local

    /// Tu id público (no es el de iCloud) y tu código para que te añadan.
    var myId: String {
        if let id = defaults.string(forKey: "SocialId") { return id }
        let id = UUID().uuidString
        defaults.set(id, forKey: "SocialId")
        return id
    }

    var myCode: String {
        if let c = defaults.string(forKey: "SocialCode") { return c }
        let c = Self.makeCode()
        defaults.set(c, forKey: "SocialCode")
        return c
    }

    /// Seis caracteres sin los que se confunden (0/O, 1/I).
    static func makeCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    var prefs: SharePrefs {
        get { defaults.data(forKey: "SocialPrefs").flatMap { try? JSONDecoder().decode(SharePrefs.self, from: $0) } ?? SharePrefs() }
        set { if let d = try? JSONEncoder().encode(newValue) { defaults.set(d, forKey: "SocialPrefs") }; objectWillChange.send() }
    }

    var friendIds: [String] {
        get { defaults.stringArray(forKey: "SocialFriendIds") ?? [] }
        set { defaults.set(newValue, forKey: "SocialFriendIds"); objectWillChange.send() }
    }

    private func saveLocal() {
        if let d = try? JSONEncoder().encode(friends) { defaults.set(d, forKey: "SocialFriendsCache") }
        if let d = try? JSONEncoder().encode(challenges) { defaults.set(d, forKey: "SocialChallenges") }
    }

    /// Lo que se publica de ti (según lo que compartes).
    func mySummary(_ vm: WorkoutViewModel, name: String) -> FriendSummary {
        let w = vm.weekStats()
        let p = prefs
        let prs = vm.topRecords(limit: 3).map { "\($0.exercise.name) \(WorkoutViewModel.weightText($0.weight, kind: $0.exercise.loadKind))" }
        return FriendSummary(id: myId, name: name.isEmpty ? "Sin nombre" : name, code: myCode,
                             weekSessions: p.sessions ? w.sessions : nil, weekSets: p.sessions ? w.sets : nil,
                             weekVolume: p.volume ? w.volume : nil, streak: p.streak ? vm.consecutiveWorkoutDays() : nil,
                             records: p.records ? prs : nil, updatedAt: Date())
    }

    // MARK: - CloudKit

    private var db: CKDatabase { CKContainer(identifier: Self.containerId).publicCloudDatabase }

    private func explain(_ error: Error) -> String {
        if let ck = error as? CKError {
            switch ck.code {
            case .notAuthenticated: return "Inicia sesión en iCloud en Ajustes del iPhone para usar amigos y retos."
            case .networkUnavailable, .networkFailure: return "Sin conexión con iCloud."
            case .quotaExceeded: return "iCloud está lleno."
            default: break
            }
        }
        return "iCloud: \(error.localizedDescription)"
    }

    /// Sube tu resumen y los marcadores de tus retos; baja amigos y marcadores.
    func refresh(_ vm: WorkoutViewModel, name: String) async {
        guard Self.available else { return }
        busy = true
        defer { busy = false }
        do {
            try await publish(mySummary(vm, name: name))
            for c in challenges { try await publishScore(c, vm.challengeScore(c.metric, from: c.start, to: c.end)) }
            try await loadFriends()
            for c in challenges { boards[c.id] = try await leaderboard(c) }
            saveLocal()
            problem = nil
        } catch {
            problem = explain(error)
        }
    }

    private func publish(_ s: FriendSummary) async throws {
        let id = CKRecord.ID(recordName: "profile-\(s.id)")
        let record = (try? await db.record(for: id)) ?? CKRecord(recordType: "Profile", recordID: id)
        record["name"] = s.name
        record["code"] = s.code
        record["weekSessions"] = s.weekSessions
        record["weekSets"] = s.weekSets
        record["weekVolume"] = s.weekVolume
        record["streak"] = s.streak
        record["records"] = s.records
        record["profileId"] = s.id
        _ = try await db.save(record)
    }

    private static func summary(from r: CKRecord) -> FriendSummary? {
        guard let id = r["profileId"] as? String else { return nil }
        return FriendSummary(id: id, name: r["name"] as? String ?? "?", code: r["code"] as? String ?? "",
                             weekSessions: r["weekSessions"] as? Int, weekSets: r["weekSets"] as? Int,
                             weekVolume: r["weekVolume"] as? Double, streak: r["streak"] as? Int,
                             records: r["records"] as? [String], updatedAt: r.modificationDate ?? Date())
    }

    private func loadFriends() async throws {
        var list: [FriendSummary] = []
        for id in friendIds {
            if let r = try? await db.record(for: CKRecord.ID(recordName: "profile-\(id)")), let s = Self.summary(from: r) { list.append(s) }
        }
        friends = list
    }

    /// Añade a alguien por su código.
    func addFriend(code raw: String) async -> Bool {
        guard Self.available else { problem = "Amigos y retos aún no están activados en esta versión."; return false }
        let code = raw.uppercased().filter { $0.isLetter || $0.isNumber }
        guard code.count == 6, code != myCode else { problem = "Ese código no vale."; return false }
        do {
            let (results, _) = try await db.records(matching: CKQuery(recordType: "Profile", predicate: NSPredicate(format: "code == %@", code)), resultsLimit: 1)
            guard let r = try results.first?.1.get(), let s = Self.summary(from: r) else { problem = String(localized: "No hay nadie con el código \(code)."); return false }
            if !friendIds.contains(s.id) { friendIds.append(s.id) }
            friends.removeAll { $0.id == s.id }
            friends.append(s)
            saveLocal()
            problem = nil
            return true
        } catch {
            problem = explain(error)
            return false
        }
    }

    func removeFriend(_ id: String) {
        friendIds.removeAll { $0 == id }
        friends.removeAll { $0.id == id }
        saveLocal()
    }

    // MARK: - Retos

    func createChallenge(title: String, metric: ChallengeMetric, days: Int, now: Date = Date()) async -> Challenge? {
        guard Self.available else { problem = "Amigos y retos aún no están activados en esta versión."; return nil }
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        let end = cal.date(byAdding: .day, value: days, to: start)!.addingTimeInterval(-1)
        let c = Challenge(id: String(UUID().uuidString.prefix(8)).lowercased(), title: title, metric: metric, start: start, end: end, creator: myId)
        let r = CKRecord(recordType: "Challenge", recordID: CKRecord.ID(recordName: "challenge-\(c.id)"))
        r["title"] = c.title; r["metric"] = c.metric.rawValue; r["start"] = c.start; r["end"] = c.end
        r["creator"] = c.creator; r["challengeId"] = c.id
        do {
            _ = try await db.save(r)
            challenges.append(c)
            saveLocal()
            return c
        } catch {
            problem = explain(error)
            return nil
        }
    }

    /// Entra en un reto desde su enlace.
    func join(challengeId: String) async -> Challenge? {
        guard Self.available else { problem = "Amigos y retos aún no están activados en esta versión."; return nil }
        if let c = challenges.first(where: { $0.id == challengeId }) { return c }
        do {
            let r = try await db.record(for: CKRecord.ID(recordName: "challenge-\(challengeId)"))
            guard let title = r["title"] as? String, let m = (r["metric"] as? String).flatMap(ChallengeMetric.init(rawValue:)),
                  let start = r["start"] as? Date, let end = r["end"] as? Date else { problem = "Ese reto no se puede leer."; return nil }
            let c = Challenge(id: challengeId, title: title, metric: m, start: start, end: end, creator: r["creator"] as? String ?? "")
            challenges.append(c)
            saveLocal()
            return c
        } catch {
            problem = explain(error)
            return nil
        }
    }

    func leave(_ id: String) {
        challenges.removeAll { $0.id == id }
        boards[id] = nil
        saveLocal()
    }

    private func publishScore(_ c: Challenge, _ score: Double) async throws {
        let id = CKRecord.ID(recordName: "entry-\(c.id)-\(myId)")
        let r = (try? await db.record(for: id)) ?? CKRecord(recordType: "ChallengeEntry", recordID: id)
        r["challengeId"] = c.id
        r["profileId"] = myId
        r["name"] = defaults.string(forKey: "user_name") ?? "Yo"
        r["score"] = score
        _ = try await db.save(r)
    }

    private func leaderboard(_ c: Challenge) async throws -> [ChallengeScore] {
        let q = CKQuery(recordType: "ChallengeEntry", predicate: NSPredicate(format: "challengeId == %@", c.id))
        let (results, _) = try await db.records(matching: q, resultsLimit: 100)
        let list = results.compactMap { try? $0.1.get() }.compactMap { r -> ChallengeScore? in
            guard let pid = r["profileId"] as? String else { return nil }
            return ChallengeScore(profileId: pid, name: r["name"] as? String ?? "?", score: r["score"] as? Double ?? 0)
        }
        return Self.rank(list)
    }

    /// De más a menos; empate, por nombre.
    static func rank(_ list: [ChallengeScore]) -> [ChallengeScore] {
        list.sorted { $0.score != $1.score ? $0.score > $1.score : $0.name < $1.name }
    }
}
