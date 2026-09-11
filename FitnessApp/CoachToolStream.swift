//
//  CoachToolStream.swift
//  ChamaFit
//
//  Chat con Claude usando herramientas: el texto llega en streaming y, si
//  Claude pide una herramienta, se ejecuta aquí, se le devuelve el resultado
//  y sigue (hasta 6 vueltas). Los bloques del asistente (texto, uso de
//  herramienta, razonamiento) se devuelven tal cual en la vuelta siguiente.
//

import Foundation

/// Junta los eventos SSE de una respuesta en bloques completos.
nonisolated struct SSEAccumulator {
    private(set) var blocks: [Int: [String: Any]] = [:]
    private var partialJSON: [Int: String] = [:]
    private(set) var stopReason: String? = nil
    private(set) var errorMessage: String? = nil
    private(set) var done = false

    /// Devuelve el texto nuevo (si lo hay) de esa línea.
    mutating func feed(_ line: String) -> String? {
        guard line.hasPrefix("data:") else { return nil }
        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return nil }
        let index = (json["index"] as? NSNumber)?.intValue ?? 0
        switch type {
        case "content_block_start":
            if var block = json["content_block"] as? [String: Any] {
                if block["type"] as? String == "tool_use" { block["input"] = [String: Any]() }
                blocks[index] = block
            }
        case "content_block_delta":
            guard let delta = json["delta"] as? [String: Any], var block = blocks[index] else { return nil }
            switch delta["type"] as? String {
            case "text_delta":
                let t = delta["text"] as? String ?? ""
                block["text"] = (block["text"] as? String ?? "") + t
                blocks[index] = block
                return t
            case "input_json_delta":
                partialJSON[index, default: ""] += delta["partial_json"] as? String ?? ""
            case "thinking_delta":
                block["thinking"] = (block["thinking"] as? String ?? "") + (delta["thinking"] as? String ?? "")
                blocks[index] = block
            case "signature_delta":
                block["signature"] = delta["signature"] as? String ?? ""
                blocks[index] = block
            default: break
            }
        case "content_block_stop":
            if let raw = partialJSON[index], var block = blocks[index] {
                block["input"] = (raw.isEmpty ? [:] : (try? JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any])) ?? [:]
                blocks[index] = block
            }
        case "message_delta":
            if let d = json["delta"] as? [String: Any], let r = d["stop_reason"] as? String { stopReason = r }
        case "message_stop":
            done = true
        case "error":
            errorMessage = (json["error"] as? [String: Any])?["message"] as? String ?? "Error de Claude."
        default: break
        }
        return nil
    }

    /// Los bloques del asistente en orden, listos para volver a mandarlos.
    var assistantContent: [[String: Any]] {
        blocks.keys.sorted().compactMap { blocks[$0] }.filter { b in
            // Un bloque de texto vacío no se puede devolver.
            !(b["type"] as? String == "text" && (b["text"] as? String ?? "").isEmpty)
        }
    }

    var toolCalls: [(id: String, name: String, input: [String: Any])] {
        blocks.keys.sorted().compactMap { i in
            guard let b = blocks[i], b["type"] as? String == "tool_use", let id = b["id"] as? String, let name = b["name"] as? String else { return nil }
            return (id, name, b["input"] as? [String: Any] ?? [:])
        }
    }
}

extension AICoachManager {

    static var toolSystem: String { system + " Tienes herramientas para consultar el historial, las estadísticas de un ejercicio, las notas y la constancia del usuario: úsalas cuando necesites datos que no estén en el resumen. Si propones cambios en la rutina, usa propose_changes (el usuario los verá con Aplicar / Descartar); nunca digas que ya están aplicados." }

    static var toolDefinitions: [[String: Any]] {
        let change: [String: Any] = [
            "type": "object",
            "properties": [
                "kind": ["type": "string", "enum": ["substitute", "sets_reps", "add", "remove", "rest", "reorder"]],
                "day": ["type": "string", "enum": WorkoutDay.allCases.map(\.rawValue), "description": "Día/hueco de la rutina. Sin día = en toda la rutina."],
                "exercise": ["type": "string", "description": "Nombre exacto del ejercicio afectado."],
                "new_exercise": ["type": "string", "description": "Para substitute: nombre del ejercicio nuevo (de la biblioteca)."],
                "sets": ["type": "integer"], "reps": ["type": "integer"], "seconds": ["type": "integer"],
                "order": ["type": "array", "items": ["type": "string"], "description": "Para reorder: nombres en el nuevo orden."],
            ],
            "required": ["kind", "exercise"],
        ]
        return [
            ["name": "history", "description": "Sesiones hechas entre dos fechas (yyyy-MM-dd), con ejercicios, series, mejor serie y notas.",
             "input_schema": ["type": "object", "properties": ["from": ["type": "string"], "to": ["type": "string"]], "required": ["from", "to"]]],
            ["name": "exercise_stats", "description": "Récord, 1RM estimado, últimas sesiones y sugerencia de hoy de un ejercicio.",
             "input_schema": ["type": "object", "properties": ["name": ["type": "string"]], "required": ["name"]]],
            ["name": "search_notes", "description": "Busca texto en las notas de sesión, los ajustes de máquina y las descripciones de ejercicios.",
             "input_schema": ["type": "object", "properties": ["query": ["type": "string"]], "required": ["query"]]],
            ["name": "consistency_report", "description": "Constancia de las últimas 8 semanas: sesiones frente al objetivo, días que se saltan y horario.",
             "input_schema": ["type": "object", "properties": [String: Any]()]],
            ["name": "propose_changes", "description": "Propone cambios en la rutina para que el usuario los revise. No los aplica.",
             "input_schema": ["type": "object", "properties": ["reason": ["type": "string"], "changes": ["type": "array", "items": change]],
                              "required": ["reason", "changes"]]],
        ]
    }

    /// Chat con herramientas. `run` ejecuta una herramienta y devuelve el texto del resultado.
    func streamWithTools(_ prompt: String, context: String, history: [(String, String)],
                         run: @escaping @MainActor (String, [String: Any]) -> String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                do {
                    var messages: [[String: Any]] = []
                    for (i, turn) in history.enumerated() {
                        messages.append(["role": "user", "content": i == 0 ? "Mis datos:\n\(context)\n\n\(turn.0)" : turn.0])
                        messages.append(["role": "assistant", "content": turn.1])
                    }
                    messages.append(["role": "user", "content": history.isEmpty ? "Mis datos:\n\(context)\n\nMi petición: \(prompt)" : prompt])
                    var shown = ""
                    for _ in 0..<6 {
                        let req = try request([
                            "model": Self.model, "max_tokens": 4096, "stream": true,
                            "system": Self.toolSystem, "output_config": ["effort": "low"],
                            "tools": Self.toolDefinitions, "messages": messages,
                        ])
                        let (bytes, resp) = try await URLSession.shared.bytes(for: req)
                        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
                            var body = ""
                            for try await line in bytes.lines { body += line; if body.count > 400 { break } }
                            throw Self.error(http.statusCode, Self.httpMessage(http.statusCode, body))
                        }
                        var acc = SSEAccumulator()
                        for try await line in bytes.lines {
                            if let t = acc.feed(line) { shown += t; continuation.yield(shown) }
                            if let e = acc.errorMessage { throw Self.error(500, e) }
                            if acc.done { break }
                        }
                        guard acc.stopReason == "tool_use", !acc.toolCalls.isEmpty else { break }
                        messages.append(["role": "assistant", "content": acc.assistantContent])
                        let results: [[String: Any]] = acc.toolCalls.map { call in
                            ["type": "tool_result", "tool_use_id": call.id, "content": run(call.name, call.input)]
                        }
                        messages.append(["role": "user", "content": results])
                        if !shown.isEmpty && !shown.hasSuffix("\n") { shown += "\n\n"; continuation.yield(shown) }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

extension WorkoutViewModel {

    /// Ejecuta una herramienta del coach. Las propuestas quedan en `CoachProposals.shared`.
    func runCoachTool(_ name: String, _ input: [String: Any]) -> String {
        switch name {
        case "history": return toolHistory(from: input["from"] as? String ?? "", to: input["to"] as? String ?? "")
        case "exercise_stats": return toolExerciseStats(input["name"] as? String ?? "")
        case "search_notes": return toolSearchNotes(input["query"] as? String ?? "")
        case "consistency_report": return toolConsistency()
        case "propose_changes":
            let raw = CoachProposals.parse(input["changes"] as? [[String: Any]] ?? [])
            let (ok, problems) = validate(raw)
            guard !ok.isEmpty else { return "No se puede proponer: " + (problems.isEmpty ? "sin cambios válidos." : problems.joined(separator: " ")) }
            CoachProposals.shared.latest = CoachProposal(reason: input["reason"] as? String ?? "", changes: ok)
            return "Propuesta lista para que el usuario la revise (\(ok.count) cambios)." + (problems.isEmpty ? "" : " Descartados: " + problems.joined(separator: " "))
        default:
            return "Herramienta desconocida."
        }
    }
}
