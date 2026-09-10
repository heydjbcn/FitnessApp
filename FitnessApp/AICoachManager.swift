//
//  AICoachManager.swift
//  ChamaFit
//
//  Coach con la API de Claude (Anthropic): chat en streaming y creación de
//  rutinas con salida estructurada. La API key la pone el usuario y vive en
//  el llavero; sin key, el coach usa la IA del iPhone (OnDeviceCoach).
//

import Foundation
import Combine

/// Una rutina propuesta por la IA, con ejercicios del catálogo.
struct GeneratedRoutine: Codable, Equatable {
    struct Item: Codable, Equatable {
        var name: String
        var sets: Int
        var reps: Int
        var restSeconds: Int
    }
    struct Day: Codable, Equatable {
        var day: String          // "Lunes"…
        var label: String        // "Pecho y tríceps"
        var exercises: [Item]
    }
    var name: String
    var notes: String
    var days: [Day]
}

/// Lo que se le pide a la IA para crear una rutina.
struct RoutineRequest: Equatable {
    var daysPerWeek = 3
    var goal = "Hipertrofia"
    var minutes = 60
    var equipment = "Gimnasio completo"
    var level = "Intermedio"

    var prompt: String {
        """
        Crea una rutina semanal de \(daysPerWeek) días para \(goal.lowercased()), sesiones de unos \(minutes) minutos, \
        nivel \(level.lowercased()), con este material: \(equipment.lowercased()). \
        Usa solo ejercicios de esta lista, escritos exactamente igual: \(ExerciseCatalog.all.map(\.name).joined(separator: ", ")). \
        Reparte los grupos musculares con cabeza, pon series, repeticiones y descanso adecuados al objetivo, \
        y en los ejercicios por tiempo (plancha y cardio) usa las repeticiones como segundos. \
        Días de la semana en español (Lunes, Martes, Miércoles, Jueves, Viernes, Sábado, Domingo). \
        En "notes", dos frases de por qué está montada así.
        """
    }
}

@MainActor
final class AICoachManager: ObservableObject {
    static let shared = AICoachManager()

    static let model = "claude-sonnet-5"
    static let system = "Eres un entrenador personal experto. Responde SIEMPRE en español de España, de forma concisa y práctica, con recomendaciones accionables. Usa los datos del usuario cuando sean relevantes. No des consejo médico."

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

    private func request(_ body: [String: Any], timeout: TimeInterval = 90) throws -> URLRequest {
        let key = apiKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { throw Self.error(401, "Falta la API key de Anthropic.") }
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!, timeoutInterval: timeout)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return req
    }

    nonisolated static func error(_ code: Int, _ msg: String) -> NSError {
        NSError(domain: "AICoach", code: code, userInfo: [NSLocalizedDescriptionKey: msg])
    }

    nonisolated static func httpMessage(_ status: Int, _ body: String) -> String {
        switch status {
        case 401: return "API key inválida."
        case 429: return "Límite de uso alcanzado, inténtalo más tarde."
        case 529, 503: return "Claude está saturado ahora mismo. Prueba en un momento."
        default: return "Error \(status). \(body.prefix(200))"
        }
    }

    // MARK: - Chat en streaming

    /// Respuesta que va llegando (texto acumulado). `history`: turnos previos (pregunta, respuesta).
    func stream(_ prompt: String, context: String, history: [(String, String)]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                do {
                    var messages: [[String: Any]] = []
                    for (i, turn) in history.enumerated() {
                        let q = i == 0 ? "Mis datos:\n\(context)\n\n\(turn.0)" : turn.0
                        messages.append(["role": "user", "content": q])
                        messages.append(["role": "assistant", "content": turn.1])
                    }
                    let q = history.isEmpty ? "Mis datos:\n\(context)\n\nMi petición: \(prompt)" : prompt
                    messages.append(["role": "user", "content": q])
                    let req = try request([
                        "model": Self.model,
                        "max_tokens": 4096,
                        "stream": true,
                        "system": Self.system,
                        "output_config": ["effort": "low"],
                        "messages": messages,
                    ])
                    let (bytes, resp) = try await URLSession.shared.bytes(for: req)
                    if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
                        var body = ""
                        for try await line in bytes.lines { body += line; if body.count > 400 { break } }
                        throw Self.error(http.statusCode, Self.httpMessage(http.statusCode, body))
                    }
                    var text = ""
                    for try await line in bytes.lines {
                        switch Self.parseSSE(line) {
                        case .text(let t): text += t; continuation.yield(text)
                        case .error(let msg): throw Self.error(500, msg)
                        case .stop: continuation.finish(); return
                        case .none: continue
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    enum SSEEvent: Equatable { case text(String), error(String), stop, none }

    /// Una línea del stream: solo interesa el texto de las respuestas (el
    /// razonamiento interno llega como "thinking_delta" y se ignora).
    nonisolated static func parseSSE(_ line: String) -> SSEEvent {
        guard line.hasPrefix("data:") else { return .none }
        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return .none }
        switch type {
        case "content_block_delta":
            if let delta = json["delta"] as? [String: Any], delta["type"] as? String == "text_delta",
               let t = delta["text"] as? String { return .text(t) }
            return .none
        case "message_stop": return .stop
        case "error":
            let msg = (json["error"] as? [String: Any])?["message"] as? String ?? "Error de Claude."
            return .error(msg)
        default: return .none
        }
    }

    // MARK: - Rutina con salida estructurada

    static var routineSchema: [String: Any] {
        let item: [String: Any] = [
            "type": "object",
            "properties": [
                "name": ["type": "string", "enum": ExerciseCatalog.all.map(\.name)],
                "sets": ["type": "integer"],
                "reps": ["type": "integer"],
                "restSeconds": ["type": "integer"],
            ],
            "required": ["name", "sets", "reps", "restSeconds"],
            "additionalProperties": false,
        ]
        let day: [String: Any] = [
            "type": "object",
            "properties": [
                "day": ["type": "string", "enum": WorkoutDay.allCases.map(\.rawValue)],
                "label": ["type": "string"],
                "exercises": ["type": "array", "items": item],
            ],
            "required": ["day", "label", "exercises"],
            "additionalProperties": false,
        ]
        return [
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "notes": ["type": "string"],
                "days": ["type": "array", "items": day],
            ],
            "required": ["name", "notes", "days"],
            "additionalProperties": false,
        ]
    }

    func generateRoutine(_ r: RoutineRequest) async throws -> GeneratedRoutine {
        let req = try request([
            "model": Self.model,
            "max_tokens": 8000,
            "system": Self.system,
            "output_config": ["effort": "medium", "format": ["type": "json_schema", "schema": Self.routineSchema]],
            "messages": [["role": "user", "content": r.prompt]],
        ], timeout: 150)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw Self.error(-1, "Sin respuesta del servidor.") }
        guard http.statusCode == 200 else {
            throw Self.error(http.statusCode, Self.httpMessage(http.statusCode, String(data: data, encoding: .utf8) ?? ""))
        }
        return try Self.decodeRoutine(from: data)
    }

    /// Saca la rutina del primer bloque de texto de la respuesta.
    nonisolated static func decodeRoutine(from data: Data) throws -> GeneratedRoutine {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if json?["stop_reason"] as? String == "refusal" { throw error(-2, "Claude no ha querido responder a esa petición.") }
        let text = (json?["content"] as? [[String: Any]])?.first { $0["type"] as? String == "text" }?["text"] as? String
        guard let text, let body = text.data(using: .utf8) else { throw error(-3, "La respuesta no trae la rutina.") }
        return try JSONDecoder().decode(GeneratedRoutine.self, from: body)
    }
}
