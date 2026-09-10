//
//  WatchConnectivityManager.swift
//  ChamaFit Watch
//
//  Recibe del iPhone la sesión que se está entrenando, el descanso en curso y
//  el acento; manda marcar / deshacer serie con respuesta, y si el iPhone no
//  está a mano, lo encola para que llegue después.
//

import Foundation
import WatchConnectivity
import SwiftUI

struct WatchExercise: Identifiable, Equatable {
    let id: String
    let name: String
    let totalSets: Int
    var completed: Int
    let weight: Double
    let reps: Int
    let seconds: Int
    let rest: Int
    let superset: Int

    var meta: String {
        var parts: [String] = []
        if seconds > 0 { parts.append("\(seconds) s") } else if reps > 0 { parts.append("\(reps) reps") }
        if weight > 0 {
            let w = weight.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(weight)) : String(format: "%.1f", weight).replacingOccurrences(of: ".", with: ",")
            parts.append("\(w) kg")
        }
        return parts.joined(separator: " · ")
    }
}

final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    @Published var dayName = ""
    @Published var sessionLabel = ""
    @Published var exercises: [WatchExercise] = []
    @Published var timerEnd: Date? = nil
    @Published var timerLabel = ""
    @Published var accent1 = "#8B5CF6"
    @Published var accent2 = "#22D3EE"
    @Published var onAccentDark = true
    @Published var lastSync: Date? = nil

    /// True mientras hay un descanso en marcha que no ha vencido.
    var restActive: Bool { (timerEnd ?? .distantPast) > Date() }

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Acciones

    func completeSet(_ id: String) {
        if let i = exercises.firstIndex(where: { $0.id == id }), exercises[i].completed < exercises[i].totalSets {
            exercises[i].completed += 1
            // El descanso arranca ya en el reloj; el iPhone confirmará la hora exacta.
            if exercises[i].completed < exercises[i].totalSets {
                timerEnd = Date().addingTimeInterval(TimeInterval(exercises[i].rest))
                timerLabel = "\(exercises[i].name) · siguiente serie \(exercises[i].completed + 1) de \(exercises[i].totalSets)"
            }
        }
        send(["action": "completeSet", "id": id])
        publishComplication()
    }

    func undoSet(_ id: String) {
        if let i = exercises.firstIndex(where: { $0.id == id }), exercises[i].completed > 0 {
            exercises[i].completed -= 1
        }
        send(["action": "undoSet", "id": id])
        publishComplication()
    }

    func stopTimer() {
        timerEnd = nil
        send(["action": "stopTimer", "id": UUID().uuidString])
        publishComplication()
    }

    func extendTimer() {
        if let end = timerEnd { timerEnd = end.addingTimeInterval(30) }
        send(["action": "extendTimer", "id": UUID().uuidString])
        publishComplication()
    }

    /// Mensaje con respuesta si el iPhone está a mano; si no, a la cola.
    private func send(_ message: [String: Any]) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        if session.isReachable {
            session.sendMessage(message, replyHandler: { [weak self] reply in
                self?.apply(reply)
            }, errorHandler: { [weak self] _ in
                self?.queue(message)
            })
        } else {
            queue(message)
        }
    }

    private func queue(_ message: [String: Any]) {
        WCSession.default.transferUserInfo(message)
    }

    // MARK: - Estado que llega del iPhone

    private func apply(_ ctx: [String: Any]) {
        guard !ctx.isEmpty else { return }
        DispatchQueue.main.async {
            self.dayName = ctx["day"] as? String ?? ""
            self.sessionLabel = ctx["label"] as? String ?? ""
            self.accent1 = ctx["accent1"] as? String ?? self.accent1
            self.accent2 = ctx["accent2"] as? String ?? self.accent2
            self.onAccentDark = ctx["onAccentDark"] as? Bool ?? true
            self.timerLabel = ctx["timerLabel"] as? String ?? ""
            self.timerEnd = (ctx["timerEnd"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
            let raw = ctx["exercises"] as? [[String: Any]] ?? []
            self.exercises = raw.map {
                WatchExercise(id: $0["id"] as? String ?? UUID().uuidString,
                              name: $0["name"] as? String ?? "",
                              totalSets: $0["totalSets"] as? Int ?? 0,
                              completed: $0["completed"] as? Int ?? 0,
                              weight: $0["weight"] as? Double ?? 0,
                              reps: $0["reps"] as? Int ?? 0,
                              seconds: $0["seconds"] as? Int ?? 0,
                              rest: $0["rest"] as? Int ?? 120,
                              superset: $0["superset"] as? Int ?? -1)
            }
            self.lastSync = Date()
            self.publishComplication()
        }
    }

    /// La esfera enseña lo mismo que la app: series de hoy, lo siguiente y el descanso.
    func publishComplication() {
        let done = exercises.reduce(0) { $0 + min($1.completed, $1.totalSets) }
        let total = exercises.reduce(0) { $0 + $1.totalSets }
        let next = exercises.first { $0.completed < $0.totalSets }.map { "\($0.name) · \($0.meta)" }
        WatchComplicationState(dayName: dayName, label: sessionLabel, done: done, total: total, next: next,
                               restEnd: restActive ? timerEnd : nil, accent1: accent1, accent2: accent2).save()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        apply(message)
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let ctx = session.receivedApplicationContext
        if !ctx.isEmpty { apply(ctx) }
    }
}
