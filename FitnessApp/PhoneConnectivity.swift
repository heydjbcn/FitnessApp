//
//  PhoneConnectivity.swift
//  FitnessApp (lado iPhone)
//
//  Sincroniza la rutina del día con el Apple Watch y recibe "completar serie"
//  desde el reloj vía WatchConnectivity.
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

    /// Envía al reloj la rutina del día actual (ejercicios + series completadas).
    func sendTodayContext() {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              let vm = viewModel else { return }
        let day = WeeklyCalendarView.getCurrentDay()
        let exercises: [[String: Any]] = (vm.dailyWorkoutRecords[day] ?? []).compactMap { rec in
            guard let ex = vm.getExercise(by: rec.exerciseId) else { return nil }
            return [
                "id": rec.id.uuidString,
                "name": ex.name,
                "totalSets": ex.totalSets,
                "completed": rec.completedSets,
                "weight": ex.weight,
                "reps": ex.repetitions
            ]
        }
        let ctx: [String: Any] = ["day": day.rawValue, "exercises": exercises]
        try? WCSession.default.updateApplicationContext(ctx)
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if message["action"] as? String == "completeSet",
               let idStr = message["id"] as? String,
               let id = UUID(uuidString: idStr) {
                let day = WeeklyCalendarView.getCurrentDay()
                self.viewModel?.completeSet(for: id, in: day)
                self.sendTodayContext()
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        sendTodayContext()
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}
