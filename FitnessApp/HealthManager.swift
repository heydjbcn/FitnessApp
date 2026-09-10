//
//  HealthManager.swift
//  ChamaFit
//
//  Salud en el iPhone: guarda cada entreno de fuerza (aunque no lleves el
//  Watch), lee y escribe el peso, y lee sueño, pulso en reposo, VFC, pasos y
//  anillos para la tarjeta de Recuperación. No es consejo médico.
//

import Foundation
import HealthKit
import Combine

/// Cómo llegas hoy: sale de sueño, pulso en reposo y VFC frente a tu media.
struct Recovery: Equatable {
    enum Level { case good, normal, easy }

    var sleepHours: Double?
    var restingHR: Double?
    var restingHRAvg: Double?
    var hrv: Double?
    var hrvAvg: Double?
    var steps: Int?
    var activeEnergy: Double?
    var exerciseMinutes: Double?
    /// Anillos de hoy: 0…1 (o más si se supera el objetivo).
    var move: Double?
    var exercise: Double?
    var stand: Double?

    var hasSignals: Bool { sleepHours != nil || (restingHR != nil && restingHRAvg != nil) || (hrv != nil && hrvAvg != nil) }

    /// Verde «día para apretar», ámbar «sesión normal», rojo «mejor suave».
    var level: Level? {
        guard hasSignals else { return nil }
        var bad = 0, warn = 0
        if let s = sleepHours { if s < 6 { bad += 1 } else if s < 7 { warn += 1 } }
        if let r = restingHR, let a = restingHRAvg, a > 0 {
            let d = r - a
            if d > 5 { bad += 1 } else if d > 3 { warn += 1 }
        }
        if let h = hrv, let a = hrvAvg, a > 0 {
            let d = (h - a) / a
            if d < -0.20 { bad += 1 } else if d < -0.10 { warn += 1 }
        }
        if bad >= 2 || (bad >= 1 && warn >= 1) { return .easy }
        if bad == 1 || warn >= 2 { return .normal }
        return .good
    }

    var headline: String {
        switch level {
        case .good: return "Día para apretar"
        case .normal: return "Sesión normal"
        case .easy: return "Mejor suave hoy"
        case nil: return "Sin datos de hoy"
        }
    }

    var advice: String {
        switch level {
        case .good: return "Has dormido bien y tu cuerpo está descansado. Buen día para intentar la sugerencia al alza."
        case .normal: return "Alguna señal algo baja. Entrena normal y escucha al cuerpo en las últimas series."
        case .easy: return "Poco sueño o pulsaciones altas. Mantén los pesos, recorta alguna serie o haz técnica."
        case nil: return "Cuando Salud tenga sueño o pulsaciones de hoy, aquí verás cómo llegas."
        }
    }
}

@MainActor
final class HealthManager: ObservableObject {
    static let shared = HealthManager()

    @Published private(set) var recovery = Recovery()
    @Published private(set) var weekSleepAvg: Double? = nil
    @Published private(set) var weekStepsAvg: Int? = nil

    private let store = HKHealthStore()

    /// Solo en un iPhone real con Salud (y nunca en pruebas: no sale el permiso).
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() && !AppDefaults.isTesting }

    /// El usuario ya pasó por la hoja de permisos (Salud no dice qué concedió de lectura).
    @Published var connected: Bool = AppDefaults.store.bool(forKey: "healthConnected") {
        didSet { AppDefaults.store.set(connected, forKey: "healthConnected") }
    }
    var saveWorkouts: Bool {
        get { AppDefaults.store.object(forKey: "healthSaveWorkouts") as? Bool ?? true }
        set { AppDefaults.store.set(newValue, forKey: "healthSaveWorkouts"); objectWillChange.send() }
    }

    private var readTypes: Set<HKObjectType> {
        var s: Set<HKObjectType> = [HKObjectType.workoutType(), HKObjectType.activitySummaryType()]
        for id: HKQuantityTypeIdentifier in [.restingHeartRate, .heartRateVariabilitySDNN, .stepCount, .activeEnergyBurned,
                                             .appleExerciseTime, .bodyMass, .bodyFatPercentage] {
            s.insert(HKQuantityType(id))
        }
        s.insert(HKCategoryType(.sleepAnalysis))
        return s
    }
    private var shareTypes: Set<HKSampleType> { [HKObjectType.workoutType(), HKQuantityType(.bodyMass)] }

    private init() {}

    /// Conecta la app con el modelo: guarda en Salud al terminar el modo entreno.
    func install(on vm: WorkoutViewModel) {
        vm.onSessionFinished = { [weak self] summary in
            guard let self, let start = summary.start, let end = summary.end else { return }
            Task { await self.saveWorkout(start: start, end: end) }
        }
    }

    func requestAccess() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            connected = true
            await refresh()
        } catch {
            connected = false
        }
    }

    // MARK: - Escribir

    /// Guarda el entreno de fuerza salvo que el Watch ya guardara uno que se solape.
    func saveWorkout(start: Date, end: Date) async {
        guard isAvailable, connected, saveWorkouts, end > start else { return }
        if await hasOverlappingWorkout(start: start, end: end) { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {}
    }

    private func hasOverlappingWorkout(start: Date, end: Date) async -> Bool {
        let predicate = HKQuery.predicateForSamples(withStart: start.addingTimeInterval(-600), end: end.addingTimeInterval(600))
        let workouts: [HKWorkout] = await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: 20, sortDescriptors: nil) { _, samples, _ in
                cont.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(q)
        }
        return workouts.contains { $0.workoutActivityType == .traditionalStrengthTraining || $0.workoutActivityType == .functionalStrengthTraining }
    }

    func saveBodyWeight(_ kg: Double, date: Date = Date()) {
        guard isAvailable, connected, kg > 0 else { return }
        let sample = HKQuantitySample(type: HKQuantityType(.bodyMass), quantity: HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg),
                                      start: date, end: date)
        store.save(sample) { _, _ in }
    }

    // MARK: - Leer

    func latestBodyWeight() async -> (kg: Double, date: Date)? {
        guard isAvailable, connected else { return nil }
        guard let s = await latestSample(.bodyMass, days: 30) else { return nil }
        return (s.quantity.doubleValue(for: .gramUnit(with: .kilo)), s.endDate)
    }

    /// Recalcula la tarjeta de Recuperación y las medias de la semana.
    func refresh() async {
        guard isAvailable, connected else { return }
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        var r = Recovery()

        r.sleepHours = await sleepHours(endingOn: today)
        r.restingHR = await latestSample(.restingHeartRate, days: 2)?.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
        r.restingHRAvg = await average(.restingHeartRate, unit: .count().unitDivided(by: .minute()), days: 30)
        r.hrv = await average(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), days: 2)
        r.hrvAvg = await average(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), days: 30)
        r.steps = await sum(.stepCount, unit: .count(), from: today, to: now).map { Int($0) }
        r.activeEnergy = await sum(.activeEnergyBurned, unit: .kilocalorie(), from: today, to: now)
        r.exerciseMinutes = await sum(.appleExerciseTime, unit: .minute(), from: today, to: now)
        if let rings = await activityRings(for: now) { (r.move, r.exercise, r.stand) = rings }
        recovery = r

        // Semana: sueño y pasos medios de los últimos 7 días.
        var sleeps: [Double] = []
        var steps: [Double] = []
        for back in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: -back, to: today),
                  let next = cal.date(byAdding: .day, value: 1, to: day) else { continue }
            if let s = await sleepHours(endingOn: day), s > 0 { sleeps.append(s) }
            if let st = await sum(.stepCount, unit: .count(), from: day, to: min(next, now)), st > 0 { steps.append(st) }
        }
        weekSleepAvg = sleeps.isEmpty ? nil : sleeps.reduce(0, +) / Double(sleeps.count)
        weekStepsAvg = steps.isEmpty ? nil : Int(steps.reduce(0, +) / Double(steps.count))
    }

    /// Horas dormidas la noche que termina el día dado (de las 18:00 anteriores a las 14:00).
    private func sleepHours(endingOn day: Date) async -> Double? {
        let start = day.addingTimeInterval(-6 * 3600)
        let end = day.addingTimeInterval(14 * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let samples: [HKCategorySample] = await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: HKCategoryType(.sleepAnalysis), predicate: predicate, limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { _, s, _ in cont.resume(returning: (s as? [HKCategorySample]) ?? []) }
            store.execute(q)
        }
        let asleep: Set<Int> = [HKCategoryValueSleepAnalysis.asleepCore.rawValue, HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                                HKCategoryValueSleepAnalysis.asleepREM.rawValue, HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue]
        // Varias fuentes (reloj, iPhone, apps) pueden solaparse: se unen los intervalos.
        let intervals = samples.filter { asleep.contains($0.value) }.map { ($0.startDate, $0.endDate) }.sorted { $0.0 < $1.0 }
        guard !intervals.isEmpty else { return nil }
        var total: TimeInterval = 0
        var cur = intervals[0]
        for iv in intervals.dropFirst() {
            if iv.0 <= cur.1 { cur.1 = max(cur.1, iv.1) } else { total += cur.1.timeIntervalSince(cur.0); cur = iv }
        }
        total += cur.1.timeIntervalSince(cur.0)
        return total / 3600
    }

    private func latestSample(_ id: HKQuantityTypeIdentifier, days: Int) async -> HKQuantitySample? {
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-Double(days) * 86_400), end: Date())
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: HKQuantityType(id), predicate: predicate, limit: 1,
                                  sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, s, _ in
                cont.resume(returning: s?.first as? HKQuantitySample)
            }
            store.execute(q)
        }
    }

    private func average(_ id: HKQuantityTypeIdentifier, unit: HKUnit, days: Int) async -> Double? {
        await statistic(id, unit: unit, from: Date().addingTimeInterval(-Double(days) * 86_400), to: Date(), options: .discreteAverage)
    }

    private func sum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, from: Date, to: Date) async -> Double? {
        await statistic(id, unit: unit, from: from, to: to, options: .cumulativeSum)
    }

    private func statistic(_ id: HKQuantityTypeIdentifier, unit: HKUnit, from: Date, to: Date,
                           options: HKStatisticsOptions) async -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: HKQuantityType(id), quantitySamplePredicate: predicate, options: options) { _, st, _ in
                let q = options.contains(.cumulativeSum) ? st?.sumQuantity() : st?.averageQuantity()
                cont.resume(returning: q?.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func activityRings(for date: Date) async -> (Double, Double, Double)? {
        let cal = Calendar.current
        var comps = cal.dateComponents([.era, .year, .month, .day], from: date)
        comps.calendar = cal
        let predicate = HKQuery.predicateForActivitySummary(with: comps)
        return await withCheckedContinuation { (cont: CheckedContinuation<(Double, Double, Double)?, Never>) in
            let q = HKActivitySummaryQuery(predicate: predicate) { _, summaries, _ in
                guard let s = summaries?.first else { cont.resume(returning: nil); return }
                func ratio(_ v: HKQuantity, _ g: HKQuantity?, _ u: HKUnit) -> Double {
                    let goal = g?.doubleValue(for: u) ?? 0
                    return goal > 0 ? v.doubleValue(for: u) / goal : 0
                }
                cont.resume(returning: (ratio(s.activeEnergyBurned, s.activeEnergyBurnedGoal, .kilocalorie()),
                                        ratio(s.appleExerciseTime, s.exerciseTimeGoal, .minute()),
                                        ratio(s.appleStandHours, s.standHoursGoal, .count())))
            }
            store.execute(q)
        }
    }
}
