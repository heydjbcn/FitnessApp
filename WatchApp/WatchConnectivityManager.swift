//
//  WatchConnectivityManager.swift
//  AppFit Watch App (target watchOS)
//
//  Recibe la rutina del día desde el iPhone y envía "completar serie".
//

import Foundation
import WatchConnectivity

struct WatchExercise: Identifiable {
    let id: String
    let name: String
    let totalSets: Int
    var completed: Int
    let weight: Double
    let reps: Int
}

final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    @Published var dayName: String = ""
    @Published var exercises: [WatchExercise] = []

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func completeSet(_ id: String) {
        // Optimista en local
        if let idx = exercises.firstIndex(where: { $0.id == id }),
           exercises[idx].completed < exercises[idx].totalSets {
            exercises[idx].completed += 1
        }
        guard WCSession.default.activationState == .activated else { return }
        WCSession.default.sendMessage(["action": "completeSet", "id": id], replyHandler: nil) { _ in }
    }

    private func apply(_ context: [String: Any]) {
        DispatchQueue.main.async {
            self.dayName = context["day"] as? String ?? ""
            let raw = context["exercises"] as? [[String: Any]] ?? []
            self.exercises = raw.map {
                WatchExercise(
                    id: $0["id"] as? String ?? UUID().uuidString,
                    name: $0["name"] as? String ?? "",
                    totalSets: $0["totalSets"] as? Int ?? 0,
                    completed: $0["completed"] as? Int ?? 0,
                    weight: $0["weight"] as? Double ?? 0,
                    reps: $0["reps"] as? Int ?? 0
                )
            }
        }
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let ctx = session.receivedApplicationContext as [String: Any]?, !ctx.isEmpty {
            apply(ctx)
        }
    }
}
