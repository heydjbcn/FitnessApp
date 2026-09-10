//
//  AICoachManager.swift
//  FitnessApp
//
//  Coach de entrenamiento con la API de Claude (Anthropic). La API key la
//  introduce el usuario (se guarda en el dispositivo); sin key, deshabilitado.
//

import Foundation
import Combine

@MainActor
final class AICoachManager: ObservableObject {
    static let shared = AICoachManager()

    @Published var apiKey: String {
        didSet { Keychain.set(apiKey, for: "anthropicAPIKey") }
    }

    private init() {
        // Las keys guardadas en UserDefaults por versiones anteriores pasan al llavero.
        if let old = AppDefaults.store.string(forKey: "anthropicAPIKey"), !old.isEmpty {
            Keychain.set(old, for: "anthropicAPIKey")
            AppDefaults.store.removeObject(forKey: "anthropicAPIKey")
        }
        apiKey = Keychain.string(for: "anthropicAPIKey") ?? ""
    }

    var hasKey: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    func ask(_ prompt: String, context: String) async throws -> String {
        let key = apiKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else {
            throw NSError(domain: "AICoach", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Falta la API key de Anthropic."])
        }
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")

        let system = "Eres un entrenador personal experto. Responde SIEMPRE en español, de forma concisa y práctica, con recomendaciones accionables. Usa los datos de la rutina del usuario cuando sean relevantes."
        let userMsg = "Datos de mi rutina actual:\n\(context)\n\nMi petición: \(prompt)"
        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 1024,
            "system": system,
            "messages": [["role": "user", "content": userMsg]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw NSError(domain: "AICoach", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sin respuesta del servidor."])
        }
        guard http.statusCode == 200 else {
            let txt = String(data: data, encoding: .utf8) ?? ""
            let msg: String
            switch http.statusCode {
            case 401: msg = "API key inválida."
            case 429: msg = "Límite de uso alcanzado, inténtalo más tarde."
            default:  msg = "Error \(http.statusCode). \(txt.prefix(200))"
            }
            throw NSError(domain: "AICoach", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = json?["content"] as? [[String: Any]]
        let text = content?.compactMap { $0["text"] as? String }.joined() ?? "(sin respuesta)"
        return text
    }
}
