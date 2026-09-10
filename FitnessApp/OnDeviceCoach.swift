//
//  OnDeviceCoach.swift
//  ChamaFit
//
//  Coach con la IA del propio iPhone (Apple Intelligence, FoundationModels):
//  gratis, privado y sin internet. El modelo tiene poco contexto (~4 k
//  tokens), así que recibe un resumen corto de la rutina y la semana.
//

import Foundation
import FoundationModels

@Generable
struct OnDeviceRoutine {
    @Guide(description: "Nombre corto de la rutina, en español")
    var name: String
    @Guide(description: "Dos frases en español explicando por qué está montada así")
    var notes: String
    @Guide(description: "Un elemento por cada día de entreno de la semana")
    var days: [OnDeviceDay]
}

@Generable
struct OnDeviceDay {
    @Guide(description: "Día de la semana", .anyOf(["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]))
    var day: String
    @Guide(description: "Nombre de la sesión, p. ej. «Pecho y tríceps»")
    var label: String
    @Guide(description: "Entre 4 y 7 ejercicios del catálogo")
    var exercises: [OnDeviceItem]
}

@Generable
struct OnDeviceItem {
    @Guide(description: "Ejercicio del catálogo", .anyOf(ExerciseCatalog.all.map(\.name)))
    var name: String
    @Guide(description: "Series", .range(1...6))
    var sets: Int
    @Guide(description: "Repeticiones (o segundos en plancha y cardio)", .range(1...120))
    var reps: Int
    @Guide(description: "Descanso entre series en segundos", .range(0...300))
    var restSeconds: Int
}

@MainActor
enum OnDeviceCoach {

    static var isAvailable: Bool {
        guard !AppDefaults.isTesting else { return false }
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// Por qué no está (para explicarlo en la app).
    static var unavailableReason: String {
        switch SystemLanguageModel.default.availability {
        case .available: return ""
        case .unavailable(.deviceNotEligible): return "Este iPhone no tiene Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled): return "Activa Apple Intelligence en Ajustes para usar el coach gratis."
        case .unavailable(.modelNotReady): return "Apple Intelligence se está descargando. Prueba en un rato."
        case .unavailable: return "Apple Intelligence no está disponible ahora."
        }
    }

    private static let instructions = """
    Eres un entrenador personal. Respondes en español de España, breve y práctico, con pasos concretos. \
    Usas los datos del usuario si ayudan. No das consejo médico.
    """

    /// Respuesta que va llegando (texto acumulado).
    static func stream(_ prompt: String, context: String, history: [(String, String)]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                do {
                    // El modelo recuerda el hilo dentro de la sesión; se rehace con lo último para no pasarse de contexto.
                    let session = LanguageModelSession(instructions: instructions)
                    var recent = ""
                    for (q, a) in history.suffix(2) { recent += "Pregunta anterior: \(q)\nTu respuesta: \(a.prefix(400))\n" }
                    let full = "Mis datos:\n\(context.prefix(1800))\n\(recent)\nMi petición: \(prompt)"
                    for try await partial in session.streamResponse(to: full) {
                        continuation.yield(partial.content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static func generateRoutine(_ r: RoutineRequest) async throws -> GeneratedRoutine {
        let session = LanguageModelSession(instructions: instructions)
        let prompt = """
        Crea una rutina semanal de \(r.daysPerWeek) días para \(r.goal.lowercased()), sesiones de unos \(r.minutes) minutos, \
        nivel \(r.level.lowercased()), con este material: \(r.equipment.lowercased()). \
        Reparte bien los grupos musculares y no repitas día de la semana.
        """
        let out = try await session.respond(to: prompt, generating: OnDeviceRoutine.self).content
        return GeneratedRoutine(
            name: out.name, notes: out.notes,
            days: out.days.map { d in
                GeneratedRoutine.Day(day: d.day, label: d.label,
                                     exercises: d.exercises.map { .init(name: $0.name, sets: $0.sets, reps: $0.reps, restSeconds: $0.restSeconds) })
            })
    }
}
