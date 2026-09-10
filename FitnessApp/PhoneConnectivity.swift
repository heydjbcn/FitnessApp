//
//  PhoneConnectivity.swift
//  ChamaFit (lado iPhone)
//
//  Manda al reloj la sesión que se está entrenando (la de Inicio, no el día
//  natural), el descanso en curso y el acento; recibe marcar / deshacer
//  serie. Cada cambio en el móvil reenvía el contexto: el reloj nunca se
//  queda atrás durante la sesión.
//

import Foundation
import WatchConnectivity

final class PhoneConnectivity: NSObject, WCSessionDelegate {
    static let shared = PhoneConnectivity()
    weak var viewModel: WorkoutViewModel?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    private var ready: Bool {
        WCSession.isSupported() && WCSession.default.activationState == .activated && WCSession.default.isPaired
    }

    /// Diccionario con todo lo que el reloj necesita pintar.
    private func context() -> [String: Any]? {
        guard let vm = viewModel else { return nil }
        let day = vm.trainingDay
        let exercises: [[String: Any]] = (vm.dailyWorkoutRecords[day] ?? []).compactMap { rec in
            guard let ex = vm.getExercise(by: rec.exerciseId) else { return nil }
            let last = rec.setLogs.last
            return [
                "id": rec.id.uuidString,
                "name": ex.name,
                "totalSets": ex.totalSets,
                "completed": rec.completedSets,
                "weight": last?.weight ?? ex.weight,
                "reps": last?.reps ?? ex.repetitions,
                "seconds": ex.segundos,
                "rest": ex.restDuration,
                "superset": rec.supersetGroup ?? -1
            ]
        }
        var ctx: [String: Any] = [
            "day": day.rawValue,
            "label": vm.label(for: day) ?? "",
            "exercises": exercises,
            "accent1": vm.activityStyle.accent1,
            "accent2": vm.activityStyle.accent2,
            "onAccentDark": vm.activityStyle.onAccentDark,
            "timerLabel": vm.timerLabel,
            "sentAt": Date().timeIntervalSince1970
        ]
        if let end = vm.timerEndDate { ctx["timerEnd"] = end.timeIntervalSince1970 }
        return ctx
    }

    /// Envía el estado completo. `updateApplicationContext` llega aunque el
    /// reloj esté dormido; se queda con el último.
    func sendTodayContext() {
        // En pruebas el reloj real no recibe la sesión de mentira.
        guard !AppDefaults.isTesting, ready, let ctx = context() else { return }
        try? WCSession.default.updateApplicationContext(ctx)
        // Si el reloj está despierto, un mensaje directo lo refresca al momento.
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(ctx, replyHandler: nil, errorHandler: nil)
        }
    }

    /// El descanso ha empezado, se ha alargado o ha parado.
    func sendTimer(endDate: Date?, label: String) {
        sendTodayContext()
    }

    // MARK: - Del reloj

    private func handle(_ message: [String: Any]) {
        guard let action = message["action"] as? String,
              let idStr = message["id"] as? String, let id = UUID(uuidString: idStr),
              let vm = viewModel else { return }
        let day = vm.trainingDay
        switch action {
        case "completeSet": vm.completeSet(for: id, in: day)
        case "undoSet": vm.undoLastSet(for: id, in: day)
        case "stopTimer": vm.stopTimer()
        case "extendTimer": vm.extendTimer(by: 30)
        default: break
        }
    }

    // WatchConnectivity llama a los delegados en su propia cola: son
    // `nonisolated` y saltan al hilo principal antes de tocar el modelo.

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            self.handle(message)
            replyHandler(self.context() ?? [:])
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handle(message)
            self.sendTodayContext()
        }
    }

    /// Cola de respaldo: lo que el reloj mandó sin cobertura llega aquí más tarde.
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            self.handle(userInfo)
            self.sendTodayContext()
        }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.sendTodayContext() }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.sendTodayContext() }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}
