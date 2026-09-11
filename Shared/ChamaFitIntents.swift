//
//  ChamaFitIntents.swift
//  ChamaFit (app + ChamaFitWidgets)
//
//  Acciones de ChamaFit para Siri, Atajos, el Botón de Acción y los
//  Controles del Centro de control. Todas son LiveActivityIntent: el sistema
//  las ejecuta en el proceso de la app (aunque esté cerrada o el móvil
//  bloqueado), que es donde viven los datos. La extensión de widgets las
//  compila solo para poder ponerlas en sus botones.
//

import AppIntents
import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum AppAction: Equatable {
    case markSet, undoSet, startRest, extendRest, stopRest, today, openWorkout
    case logWeight(Double)
    /// Serie con peso (en la unidad de la app) y repeticiones dichos a Siri.
    case logSet(weight: Double, reps: Int)
}

/// Puente entre los intents (que no conocen el modelo) y la app. La app lo
/// rellena al arrancar (`FitnessAppApp.init`); si una orden llega antes, espera.
@MainActor
final class AppActionBridge {
    static let shared = AppActionBridge()
    var handler: ((AppAction) -> String)?
    private var pending: [AppAction] = []
    private init() {}

    func run(_ action: AppAction) -> String {
        if let handler { return handler(action) }
        pending.append(action)
        return "Abriendo ChamaFit…"
    }

    func flushPending() {
        guard let handler else { return }
        let queued = pending
        pending = []
        queued.forEach { _ = handler($0) }
    }
}

/// Estado del descanso que ven los Controles (App Group).
enum SharedRestState {
    static let key = "RestEnd"
    static var end: Date? {
        get { UserDefaults(suiteName: TodaySummary.appGroup)?.object(forKey: key) as? Date }
        set { UserDefaults(suiteName: TodaySummary.appGroup)?.set(newValue, forKey: key) }
    }
    static var isActive: Bool { (end ?? .distantPast) > Date() }
}

// MARK: - Intents

struct MarkSetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Marcar serie"
    static let description = IntentDescription("Marca la siguiente serie del entreno de hoy y arranca el descanso.")
    init() {}
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = await MainActor.run { AppActionBridge.shared.run(.markSet) }
        return .result(dialog: "\(text)")
    }
}

struct UndoSetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Deshacer serie"
    static let description = IntentDescription("Quita la última serie marcada.")
    init() {}
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = await MainActor.run { AppActionBridge.shared.run(.undoSet) }
        return .result(dialog: "\(text)")
    }
}

struct StartRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Empezar descanso"
    static let description = IntentDescription("Arranca el descanso del ejercicio que toca.")
    init() {}
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = await MainActor.run { AppActionBridge.shared.run(.startRest) }
        return .result(dialog: "\(text)")
    }
}

struct AddRestTimeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Alargar descanso 30 segundos"
    static let description = IntentDescription("Añade 30 segundos al descanso en curso.")
    init() {}
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = await MainActor.run { AppActionBridge.shared.run(.extendRest) }
        return .result(dialog: "\(text)")
    }
}

struct EndRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Terminar descanso"
    static let description = IntentDescription("Para el descanso en curso.")
    init() {}
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = await MainActor.run { AppActionBridge.shared.run(.stopRest) }
        return .result(dialog: "\(text)")
    }
}

/// El conmutador del Control «Descanso»: encendido arranca, apagado para.
struct ToggleRestIntent: SetValueIntent, LiveActivityIntent {
    static let title: LocalizedStringResource = "Descanso"
    @Parameter(title: "En marcha") var value: Bool
    init() {}
    func perform() async throws -> some IntentResult {
        _ = await MainActor.run { AppActionBridge.shared.run(value ? .startRest : .stopRest) }
        return .result()
    }
}

struct TodayWorkoutIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "¿Qué me toca hoy?"
    static let description = IntentDescription("Te dice la sesión de hoy, cuánto llevas y lo siguiente.")
    init() {}
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = await MainActor.run { AppActionBridge.shared.run(.today) }
        return .result(dialog: "\(text)")
    }
}

struct StartWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Empezar entreno"
    static let description = IntentDescription("Abre ChamaFit en el modo entreno.")
    static let openAppWhenRun = true
    init() {}
    func perform() async throws -> some IntentResult {
        _ = await MainActor.run { AppActionBridge.shared.run(.openWorkout) }
        return .result()
    }
}

/// «Apunta una serie en ChamaFit» → Siri pregunta peso y repeticiones.
struct LogSetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Apuntar serie"
    static let description = IntentDescription("Apunta la siguiente serie del entreno de hoy con el peso y las repeticiones que digas.")
    /// En la unidad que tengas elegida en la app (kg o lb). 0 = peso corporal.
    @Parameter(title: "Peso", inclusiveRange: (0, 700)) var weight: Double
    @Parameter(title: "Repeticiones", inclusiveRange: (1, 100)) var reps: Int
    static var parameterSummary: some ParameterSummary { Summary("Apuntar \(\.$weight) por \(\.$reps)") }
    init() {}
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = await MainActor.run { AppActionBridge.shared.run(.logSet(weight: weight, reps: reps)) }
        return .result(dialog: "\(text)")
    }
}

struct LogBodyWeightIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Apuntar peso corporal"
    static let description = IntentDescription("Guarda tu peso de hoy en ChamaFit (y en Salud si le has dado permiso).")
    /// En la unidad que tengas elegida en la app (kg o lb).
    @Parameter(title: "Peso", inclusiveRange: (20, 700)) var weight: Double
    init() {}
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = await MainActor.run { AppActionBridge.shared.run(.logWeight(weight)) }
        return .result(dialog: "\(text)")
    }
}
