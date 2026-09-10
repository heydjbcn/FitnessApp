//
//  WorkoutSessionManager.swift
//  ChamaFit Watch
//
//  Sesión de entrenamiento de fuerza en el reloj (HealthKit): mantiene la
//  app en primer plano, lee pulsaciones y calorías en vivo y, al terminar,
//  guarda el entrenamiento en Salud para que cuente en los anillos.
//

import Foundation
import HealthKit

final class WorkoutSessionManager: NSObject, ObservableObject {
    static let shared = WorkoutSessionManager()

    @Published var isRunning = false
    @Published var heartRate: Double = 0
    @Published var activeCalories: Double = 0
    @Published var elapsed: TimeInterval = 0
    @Published var authorized = false

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var ticker: Timer?

    private override init() {
        super.init()
        refreshAuthorization()
    }

    private var typesToShare: Set<HKSampleType> { [HKObjectType.workoutType()] }
    private var typesToRead: Set<HKObjectType> {
        [HKQuantityType(.heartRate), HKQuantityType(.activeEnergyBurned), HKObjectType.activitySummaryType()]
    }

    private func refreshAuthorization() {
        authorized = store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    func requestAuthorization(then completion: (() -> Void)? = nil) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        store.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.refreshAuthorization()
                completion?()
            }
        }
    }

    // MARK: - Empezar / terminar

    /// La primera vez pide permiso y arranca cuando el usuario responde; si lo
    /// deniega, no hay sesión (el reloj sigue sirviendo para marcar series).
    func start() {
        guard !isRunning, HKHealthStore.isHealthDataAvailable() else { return }
        if !authorized {
            requestAuthorization { [weak self] in
                guard let self, self.authorized else { return }
                self.beginSession()
            }
            return
        }
        beginSession()
    }

    private func beginSession() {
        guard !isRunning else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        do {
            let s = try HKWorkoutSession(healthStore: store, configuration: config)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            s.delegate = self
            b.delegate = self
            session = s
            builder = b
            let start = Date()
            s.startActivity(with: start)
            b.beginCollection(withStart: start) { _, _ in }
            isRunning = true
            elapsed = 0
            ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                DispatchQueue.main.async { self?.elapsed = self?.builder?.elapsedTime ?? 0 }
            }
        } catch {
            session = nil
            builder = nil
        }
    }

    func end() {
        guard isRunning else { return }
        ticker?.invalidate()
        ticker = nil
        session?.end()
        builder?.endCollection(withEnd: Date()) { [weak self] _, _ in
            self?.builder?.finishWorkout { _, _ in
                DispatchQueue.main.async {
                    self?.isRunning = false
                    self?.session = nil
                    self?.builder = nil
                }
            }
        }
    }

    var elapsedText: String {
        let s = Int(elapsed)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        if toState == .ended {
            DispatchQueue.main.async { self.isRunning = false }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async { self.isRunning = false }
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let stats = workoutBuilder.statistics(for: quantityType) else { continue }
            DispatchQueue.main.async {
                switch quantityType {
                case HKQuantityType(.heartRate):
                    self.heartRate = stats.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? self.heartRate
                case HKQuantityType(.activeEnergyBurned):
                    self.activeCalories = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? self.activeCalories
                default: break
                }
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
