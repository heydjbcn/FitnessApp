//
//  RestActivity.swift
//  ChamaFit (app + ChamaFitWidgets)
//
//  Lo que la app y la extensión de widgets comparten para la Live Activity
//  del descanso: los atributos de la actividad y los intents de sus botones.
//  Los intents son LiveActivityIntent: se ejecutan en el proceso de la app,
//  así que tocan el temporizador real.
//

import ActivityKit
import AppIntents
import Foundation

struct RestActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Cuándo empezó y cuándo acaba: el sistema cuenta solo con `Text(timerInterval:)`.
        var startDate: Date
        var endDate: Date
        /// "Press militar · siguiente serie 3 de 4"
        var label: String
        var finished: Bool = false
    }

    /// "Jueves · Hombro y core"
    var sessionName: String
    /// Los dos extremos del degradado del acento, en hex, y si el texto encima va oscuro.
    var accent1: String
    var accent2: String
    var onAccentDark: Bool
}

/// +30 s desde la pantalla bloqueada, la Dynamic Island o el reloj.
struct ExtendRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Alargar descanso"
    static let description = IntentDescription("Añade 30 segundos al descanso en curso.")

    init() {}

    func perform() async throws -> some IntentResult {
        await MainActor.run { RestTimerBridge.shared.extend?() }
        return .result()
    }
}

/// Parar el descanso desde fuera de la app.
struct StopRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Parar descanso"
    static let description = IntentDescription("Termina el descanso en curso.")

    init() {}

    func perform() async throws -> some IntentResult {
        await MainActor.run { RestTimerBridge.shared.stop?() }
        return .result()
    }
}

/// Puente entre los intents (que no conocen el ViewModel) y el temporizador.
/// La app lo rellena al arrancar; en la extensión queda vacío y no hace nada.
@MainActor
final class RestTimerBridge {
    static let shared = RestTimerBridge()
    var extend: (() -> Void)?
    var stop: (() -> Void)?
    private init() {}
}
