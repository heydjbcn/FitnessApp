//
//  DietaClient.swift
//  ChamaFit
//
//  Cliente del servidor de la app Dieta de Jordi (solo por Tailscale):
//  menú de la semana con macros, marcar comido, productos por código de
//  barras y peso en los dos sentidos. El token va al llavero y no caduca.
//

import Foundation

// MARK: - Modelos (forma de la API de Dieta)

nonisolated struct DietaRecipe: Codable, Equatable, Sendable {
    var title: String
    /// Por 100 g.
    var kcal: Double
    var protein: Double
    var fiber: Double?
    var photoUrl: String?
}

nonisolated struct DietaMeal: Codable, Equatable, Identifiable, Sendable {
    var id: String
    /// 0 = domingo … 6 = sábado.
    var weekday: Int
    var slot: String
    var grams: Double
    var eaten: Bool
    var recipe: DietaRecipe

    var kcal: Double { grams / 100 * recipe.kcal }
    var protein: Double { grams / 100 * recipe.protein }

    static let slotOrder = ["desayuno", "media_manana", "comida", "merienda", "cena"]
    var slotLabel: String {
        switch slot {
        case "desayuno": return "Desayuno"
        case "media_manana": return "Media mañana"
        case "comida": return "Comida"
        case "merienda": return "Merienda"
        case "cena": return "Cena"
        default: return slot.capitalized
        }
    }
}

nonisolated struct DietaTargets: Codable, Equatable, Sendable {
    var kcal: Double
    var protein: Double
    var isGymDay: Bool?
}

nonisolated struct DietaDay: Codable, Equatable, Sendable {
    var weekday: Int
    var targets: DietaTargets
}

nonisolated struct DietaPlan: Codable, Equatable, Sendable {
    var id: String
    var startDate: Date
    var meals: [DietaMeal]
    var days: [DietaDay]

    /// Día de Dieta (0 = domingo) para una fecha.
    static func weekday(of date: Date) -> Int { Calendar(identifier: .gregorian).component(.weekday, from: date) - 1 }

    func meals(on date: Date) -> [DietaMeal] {
        let wd = Self.weekday(of: date)
        return meals.filter { $0.weekday == wd }
            .sorted { (DietaMeal.slotOrder.firstIndex(of: $0.slot) ?? 9) < (DietaMeal.slotOrder.firstIndex(of: $1.slot) ?? 9) }
    }

    func targets(on date: Date) -> DietaTargets? { days.first { $0.weekday == Self.weekday(of: date) }?.targets }

    /// ¿El plan es de la semana de esa fecha? (empieza en lunes)
    func covers(_ date: Date) -> Bool {
        date >= startDate.addingTimeInterval(-86_400) && date < startDate.addingTimeInterval(8 * 86_400)
    }
}

nonisolated struct DietaWeight: Codable, Equatable, Sendable {
    var date: Date
    var kg: Double
}

/// Producto por código de barras (de Dieta o de Open Food Facts), por 100 g.
nonisolated struct FoodProduct: Equatable, Sendable {
    var ean: String
    var name: String
    var brand: String?
    var kcal: Double
    var protein: Double
    var source: String
}

// MARK: - Cliente

nonisolated enum DietaError: LocalizedError, Equatable {
    case notConnected, unauthorized, notFound, server(String), network
    var errorDescription: String? {
        switch self {
        case .notConnected: return "No estás conectado a Dieta."
        case .unauthorized: return "Dieta no reconoce tu sesión. Vuelve a entrar."
        case .notFound: return "No encontrado."
        case .server(let m): return m
        case .network: return "No se llega al servidor de Dieta. ¿Está Tailscale activo en el iPhone?"
        }
    }
}

nonisolated final class DietaClient: Sendable {
    static let defaultURL = "https://dieta.tail291630.ts.net"
    static let tokenKey = "dieta.token"

    let baseURL: URL
    let session: URLSession
    let token: String?

    init(baseURL: URL, token: String?, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
    }

    /// Fechas de Prisma: ISO 8601 con o sin milisegundos, o solo el día.
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { dec in
            let s = try dec.singleValueContainer().decode(String.self)
            let withMs = ISO8601DateFormatter(); withMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let plain = ISO8601DateFormatter(); plain.formatOptions = [.withInternetDateTime]
            if let date = withMs.date(from: s) ?? plain.date(from: s) { return date }
            let day = DateFormatter(); day.dateFormat = "yyyy-MM-dd"; day.timeZone = TimeZone(identifier: "UTC")
            if let date = day.date(from: s) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: dec.codingPath, debugDescription: String(localized: "Fecha rara: \(s)")))
        }
        return d
    }()

    private func request(_ path: String, method: String = "GET", body: [String: Any]? = nil, auth: Bool = true) async throws -> Data {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.timeoutInterval = 20
        if auth {
            guard let token else { throw DietaError.notConnected }
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let data: Data, resp: URLResponse
        do { (data, resp) = try await session.data(for: req) } catch { throw DietaError.network }
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        switch code {
        case 200..<300: return data
        case 401: throw DietaError.unauthorized
        case 404: throw DietaError.notFound
        default:
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw DietaError.server(msg ?? String(localized: "Error \(code) de Dieta."))
        }
    }

    /// Devuelve el token.
    func login(email: String, password: String) async throws -> String {
        let data = try await request("auth/login", method: "POST", body: ["email": email, "password": password], auth: false)
        guard let token = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["token"] as? String else {
            throw DietaError.server("Respuesta de login inesperada.")
        }
        return token
    }

    /// nil = no hay plan esta semana.
    func currentPlan() async throws -> DietaPlan? {
        do {
            return try Self.decoder.decode(DietaPlan.self, from: try await request("plan/current"))
        } catch DietaError.notFound {
            return nil
        }
    }

    func setEaten(_ mealId: String, _ eaten: Bool) async throws {
        _ = try await request("plan/meals/\(mealId)", method: "PATCH", body: ["eaten": eaten])
    }

    func weights() async throws -> [DietaWeight] {
        try Self.decoder.decode([DietaWeight].self, from: try await request("weight"))
    }

    func postWeight(_ kg: Double, date: Date) async throws {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        _ = try await request("weight", method: "POST", body: ["kg": kg, "date": f.string(from: date)])
    }

    func product(ean: String) async throws -> FoodProduct? {
        do {
            let data = try await request("products/ean/\(ean)")
            return Self.parseDietaProduct(data, ean: ean)
        } catch DietaError.notFound {
            return nil
        }
    }

    static func parseDietaProduct(_ data: Data, ean: String) -> FoodProduct? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let product = json["product"] as? [String: Any]
        guard let n = json["nutrition"] as? [String: Any], let kcal = (n["kcal"] as? NSNumber)?.doubleValue else { return nil }
        let name = (product?["name"] as? String) ?? (n["productName"] as? String) ?? String(localized: "Producto \(ean)")
        return FoodProduct(ean: ean, name: name, brand: n["brands"] as? String, kcal: kcal,
                           protein: (n["protein"] as? NSNumber)?.doubleValue ?? 0, source: "Dieta")
    }
}

/// Open Food Facts directo (sin Dieta o si Dieta no lo tiene).
nonisolated enum OpenFoodFacts {
    static func product(ean: String, session: URLSession = .shared) async -> FoodProduct? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(ean).json?fields=product_name,brands,nutriments") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("ChamaFit/2.0 (iOS)", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 15
        guard let (data, resp) = try? await session.data(for: req), (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return parse(data, ean: ean)
    }

    static func parse(_ data: Data, ean: String) -> FoodProduct? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              (json["status"] as? NSNumber)?.intValue == 1,
              let p = json["product"] as? [String: Any],
              let n = p["nutriments"] as? [String: Any] else { return nil }
        let kcal = (n["energy-kcal_100g"] as? NSNumber)?.doubleValue
            ?? ((n["energy_100g"] as? NSNumber)?.doubleValue).map { $0 / 4.184 }
        guard let kcal else { return nil }
        let name = (p["product_name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? String(localized: "Producto \(ean)")
        return FoodProduct(ean: ean, name: name, brand: p["brands"] as? String, kcal: kcal,
                           protein: (n["proteins_100g"] as? NSNumber)?.doubleValue ?? 0, source: "Open Food Facts")
    }
}
