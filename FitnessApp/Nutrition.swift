//
//  Nutrition.swift
//  ChamaFit
//
//  Nutrición del día: el menú de Dieta (si estás conectado), el agua y lo
//  que apuntas fuera del plan (a mano o escaneando). Lo local se queda en
//  el iPhone; el menú se guarda en caché para verlo sin conexión.
//

import Foundation
import Combine
import HealthKit

struct FoodLog: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var kcal: Double
    var protein: Double
    var grams: Double? = nil
    var ean: String? = nil
    var date = Date()
}

@MainActor
final class Nutrition: ObservableObject {
    static let shared = Nutrition()

    let defaults: UserDefaults
    @Published private(set) var plan: DietaPlan? = nil
    @Published private(set) var syncing = false
    @Published var lastError: String? = nil

    init(defaults: UserDefaults = AppDefaults.store) {
        self.defaults = defaults
        plan = defaults.data(forKey: "DietaPlanCache").flatMap { try? DietaClient.decoder.decode(DietaPlan.self, from: $0) }
    }

    private static func dayKey(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: d)
    }

    // MARK: - Conexión con Dieta

    var baseURL: String {
        get { defaults.string(forKey: "DietaURL") ?? DietaClient.defaultURL }
        set { defaults.set(newValue, forKey: "DietaURL"); objectWillChange.send() }
    }

    var token: String? {
        get { AppDefaults.isTesting ? defaults.string(forKey: "DietaTokenTest") : Keychain.string(for: DietaClient.tokenKey) }
        set {
            if AppDefaults.isTesting { defaults.set(newValue, forKey: "DietaTokenTest") } else { Keychain.set(newValue, for: DietaClient.tokenKey) }
            objectWillChange.send()
        }
    }

    var connected: Bool { token != nil }

    var syncWeight: Bool {
        get { defaults.object(forKey: "DietaSyncWeight") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "DietaSyncWeight"); objectWillChange.send() }
    }

    /// Sesión de red que se puede cambiar en pruebas.
    var session: URLSession = .shared

    func client() -> DietaClient? {
        guard let url = URL(string: baseURL) else { return nil }
        return DietaClient(baseURL: url, token: token, session: session)
    }

    func connect(email: String, password: String) async -> Bool {
        lastError = nil
        guard let url = URL(string: baseURL) else { lastError = "La dirección no es válida."; return false }
        do {
            token = try await DietaClient(baseURL: url, token: nil, session: session).login(email: email, password: password)
            await refresh()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func disconnect() {
        token = nil
        plan = nil
        defaults.removeObject(forKey: "DietaPlanCache")
    }

    /// Trae el menú de la semana (y deja caché).
    func refresh() async {
        guard let c = client(), connected else { return }
        syncing = true
        defer { syncing = false }
        do {
            let p = try await c.currentPlan()
            plan = p
            if let p, let d = try? JSONEncoder().encode(p) { defaults.set(d, forKey: "DietaPlanCache") }
            else { defaults.removeObject(forKey: "DietaPlanCache") }
            lastError = nil
        } catch DietaError.unauthorized {
            lastError = DietaError.unauthorized.errorDescription
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Marca un plato como comido (optimista: si falla, vuelve atrás).
    func setEaten(_ meal: DietaMeal, _ eaten: Bool) async {
        guard var p = plan, let i = p.meals.firstIndex(where: { $0.id == meal.id }) else { return }
        p.meals[i].eaten = eaten
        plan = p
        do { try await client()?.setEaten(meal.id, eaten) } catch {
            p.meals[i].eaten = !eaten
            plan = p
            lastError = error.localizedDescription
        }
        if let d = try? JSONEncoder().encode(p) { defaults.set(d, forKey: "DietaPlanCache") }
    }

    // MARK: - Peso en los dos sentidos

    /// Manda a Dieta un peso apuntado en ChamaFit.
    func pushWeight(_ kg: Double, date: Date) {
        guard connected, syncWeight, let c = client() else { return }
        Task { try? await c.postWeight(kg, date: date) }
    }

    /// Trae de Dieta los pesos que ChamaFit no tiene.
    func pullWeights(into vm: WorkoutViewModel) async {
        guard connected, syncWeight, let c = client(), let list = try? await c.weights() else { return }
        for w in list { vm.importBodyWeight(w.kg, date: w.date) }
    }

    // MARK: - Hoy

    func meals(on date: Date = Date()) -> [DietaMeal] {
        guard let p = plan, p.covers(date) else { return [] }
        return p.meals(on: date)
    }

    func targets(on date: Date = Date()) -> DietaTargets? {
        guard let p = plan, p.covers(date) else { return nil }
        return p.targets(on: date)
    }

    // MARK: - Registro rápido

    func logs(on date: Date = Date()) -> [FoodLog] {
        let all = defaults.data(forKey: "FoodLogs").flatMap { try? JSONDecoder().decode([String: [FoodLog]].self, from: $0) } ?? [:]
        return all[Self.dayKey(date)] ?? []
    }

    func addLog(_ log: FoodLog) {
        var all = defaults.data(forKey: "FoodLogs").flatMap { try? JSONDecoder().decode([String: [FoodLog]].self, from: $0) } ?? [:]
        all[Self.dayKey(log.date), default: []].append(log)
        // Solo los últimos 90 días.
        let keep = Set((0..<90).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()).map(Self.dayKey) })
        all = all.filter { keep.contains($0.key) }
        if let d = try? JSONEncoder().encode(all) { defaults.set(d, forKey: "FoodLogs") }
        objectWillChange.send()
    }

    func removeLog(_ id: UUID, on date: Date = Date()) {
        var all = defaults.data(forKey: "FoodLogs").flatMap { try? JSONDecoder().decode([String: [FoodLog]].self, from: $0) } ?? [:]
        all[Self.dayKey(date)]?.removeAll { $0.id == id }
        if let d = try? JSONEncoder().encode(all) { defaults.set(d, forKey: "FoodLogs") }
        objectWillChange.send()
    }

    /// Lo comido: platos del plan marcados más lo apuntado a mano.
    func eaten(on date: Date = Date()) -> (kcal: Double, protein: Double) {
        let fromPlan = meals(on: date).filter(\.eaten)
        let extra = logs(on: date)
        return (fromPlan.reduce(0) { $0 + $1.kcal } + extra.reduce(0) { $0 + $1.kcal },
                fromPlan.reduce(0) { $0 + $1.protein } + extra.reduce(0) { $0 + $1.protein })
    }

    // MARK: - Agua

    var waterGoal: Int {
        get { defaults.object(forKey: "WaterGoal") as? Int ?? 2000 }
        set { defaults.set(max(500, min(6000, newValue)), forKey: "WaterGoal"); objectWillChange.send() }
    }

    var waterToHealth: Bool {
        get { defaults.object(forKey: "WaterToHealth") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "WaterToHealth"); objectWillChange.send() }
    }

    func water(on date: Date = Date()) -> Int {
        (defaults.dictionary(forKey: "Water") as? [String: Int])?[Self.dayKey(date)] ?? 0
    }

    func addWater(_ ml: Int, date: Date = Date()) {
        var all = (defaults.dictionary(forKey: "Water") as? [String: Int]) ?? [:]
        let k = Self.dayKey(date)
        all[k] = max(0, (all[k] ?? 0) + ml)
        defaults.set(all, forKey: "Water")
        objectWillChange.send()
        if ml > 0, waterToHealth { HealthManager.shared.saveWater(ml: Double(ml), date: date) }
        HapticManager.shared.selectionFeedback()
    }

    // MARK: - Código de barras

    /// Dieta primero (sabe de Mercadona); si no, Open Food Facts.
    func lookup(ean: String) async -> FoodProduct? {
        if connected, let c = client(), let p = try? await c.product(ean: ean) { return p }
        return await OpenFoodFacts.product(ean: ean, session: session)
    }
}
