import Foundation
import SwiftUI
import Combine
import HealthKit

// MARK: - Data Models
struct ActivityData {
    let steps: Int
    let activeCalories: Int
    let calories: Int
    let distance: Double
    let heartRate: Double
    let date: Date
}

struct WorkoutData: Identifiable {
    let id = UUID()
    let activityType: String
    let name: String
    let duration: TimeInterval
    let totalEnergyBurned: Double
    let totalDistance: Double?
    let calories: Double
    let date: Date
    let type: String
    let startDate: Date
}

@MainActor
class HealthKitManagerSimple: ObservableObject {
    static let shared = HealthKitManagerSimple()
    
    private let healthStore = HKHealthStore()
    
    // Propiedad calculada para compatibilidad
    var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    @Published var isAuthorized: Bool = false
    @Published var isLoading: Bool = false
    @Published var recentActivityData: ActivityData?
    @Published var recentWorkoutsData: [WorkoutData] = []
    @Published var appleWatchConnected: Bool = false
    
    @Published var todaySteps: Int = 0
    @Published var todayCalories: Double = 0.0
    @Published var todayDistance: Double = 0.0
    @Published var heartRate: Double = 0.0
    @Published var weeklySteps: Int = 0
    @Published var weeklyStepsArray: [Int] = [0, 0, 0, 0, 0, 0, 0]
    @Published var workouts: [HKWorkout] = []
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit no está disponible")
            return
        }
        
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        let stepStatus = healthStore.authorizationStatus(for: stepsType)
        let caloriesStatus = healthStore.authorizationStatus(for: caloriesType)
        
        print("🔍 Estado autorización pasos: \(stepStatus.rawValue)")
        print("🔍 Estado autorización calorías: \(caloriesStatus.rawValue)")
        
        // Solo consideramos autorizado si ambos están explícitamente autorizados
        self.isAuthorized = (stepStatus == .sharingAuthorized && caloriesStatus == .sharingAuthorized)
        
        if !self.isAuthorized {
            print("❌ HealthKit no completamente autorizado - Pasos: \(stepStatus), Calorías: \(caloriesStatus)")
        } else {
            print("✅ HealthKit completamente autorizado")
        }
    }
    
    func requestPermissions() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit no está disponible en este dispositivo")
            return false
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType()
        ]
        
        print("🔑 Solicitando permisos de HealthKit...")
        
        do {
            try await healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: typesToRead)
            print("✅ Permisos solicitados correctamente")
            
            await MainActor.run {
                self.checkAuthorizationStatus()
            }
            
            return self.isAuthorized
        } catch {
            print("❌ Error solicitando permisos: \(error)")
            return false
        }
    }
    
    func fetchTodaySteps() async {
        guard isAuthorized else {
            print("❌ No autorizado para acceder a pasos")
            return
        }
        
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: today, options: .strictStartDate)
        
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    print("❌ Error obteniendo pasos: \(error)")
                    continuation.resume()
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                print("🚶 Pasos de hoy: \(Int(steps))")
                
                Task { @MainActor in
                    self.todaySteps = Int(steps)
                }
                
                continuation.resume()
            }
            
            self.healthStore.execute(query)
        }
    }
    
    func fetchTodayCalories() async {
        guard isAuthorized else {
            print("❌ No autorizado para acceder a calorías")
            return
        }
        
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: today, options: .strictStartDate)
        
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: caloriesType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    print("❌ Error obteniendo calorías: \(error)")
                    continuation.resume()
                    return
                }
                
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                print("🔥 Calorías de hoy: \(calories)")
                
                Task { @MainActor in
                    self.todayCalories = calories
                }
                
                continuation.resume()
            }
            
            self.healthStore.execute(query)
        }
    }
    
    func fetchTodayDistance() async {
        guard isAuthorized else {
            print("❌ No autorizado para acceder a distancia")
            return
        }
        
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: today, options: .strictStartDate)
        
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    print("❌ Error obteniendo distancia: \(error)")
                    continuation.resume()
                    return
                }
                
                let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                let distanceInKm = distance / 1000.0
                print("🏃 Distancia de hoy: \(distanceInKm) km")
                
                Task { @MainActor in
                    self.todayDistance = distanceInKm
                }
                
                continuation.resume()
            }
            
            self.healthStore.execute(query)
        }
    }
    
    func fetchHeartRate() async {
        guard isAuthorized else {
            print("❌ No autorizado para acceder a ritmo cardíaco")
            return
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: today, options: .strictStartDate)
        
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .mostRecent) { _, result, error in
                if let error = error {
                    print("❌ Error obteniendo ritmo cardíaco: \(error)")
                    continuation.resume()
                    return
                }
                
                let heartRate = result?.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 75.0
                print("❤️ Ritmo cardíaco: \(heartRate) bpm")
                
                Task { @MainActor in
                    self.heartRate = heartRate
                }
                
                continuation.resume()
            }
            
            self.healthStore.execute(query)
        }
    }
    
    func fetchWeeklySteps() async {
        guard isAuthorized else {
            print("❌ No autorizado para acceder a pasos semanales")
            return
        }
        
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: today, options: .strictStartDate)
        
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    print("❌ Error obteniendo pasos semanales: \(error)")
                    continuation.resume()
                    return
                }
                
                let weekSteps = Int(result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0)
                
                // Generar datos simulados para el gráfico semanal
                let simulatedWeeklySteps = [8500, 7200, 9100, 6800, 10200, 5400, 7800]
                
                Task { @MainActor in
                    self.weeklySteps = weekSteps
                    self.weeklyStepsArray = simulatedWeeklySteps
                    print("📅 Pasos semanales: \(weekSteps)")
                }
                
                continuation.resume()
            }
            
            self.healthStore.execute(query)
        }
    }
    
    func fetchRecentWorkouts() async {
        guard isAuthorized else {
            print("❌ No autorizado para acceder a entrenamientos")
            return
        }
        
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: 10, sortDescriptors: [sortDescriptor]) { _, results, error in
                if let error = error {
                    print("❌ Error obteniendo entrenamientos: \(error)")
                    continuation.resume()
                    return
                }
                
                guard let workouts = results as? [HKWorkout] else {
                    print("⚠️ No se encontraron entrenamientos")
                    continuation.resume()
                    return
                }
                
                print("💪 Entrenamientos encontrados: \(workouts.count)")
                
                Task { @MainActor in
                    self.workouts = workouts
                }
                
                continuation.resume()
            }
            
            self.healthStore.execute(query)
        }
    }
    
    func createWorkout(type: HKWorkoutActivityType, startDate: Date, duration: TimeInterval, calories: Double, distance: Double?) async -> Bool {
        let endDate = startDate.addingTimeInterval(duration)
        
        let energyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
        var totalDistance: HKQuantity?
        if let dist = distance {
            totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: dist)
        }
        
        let workout = HKWorkout(
            activityType: type,
            start: startDate,
            end: endDate,
            duration: duration,
            totalEnergyBurned: energyBurned,
            totalDistance: totalDistance,
            metadata: nil
        )
        
        do {
            try await healthStore.save(workout)
            print("✅ Entrenamiento guardado exitosamente")
            return true
        } catch {
            print("❌ Error guardando entrenamiento: \(error)")
            return false
        }
    }
    
    func loadAllData() async {
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchTodaySteps() }
            group.addTask { await self.fetchTodayCalories() }
            group.addTask { await self.fetchTodayDistance() }
            group.addTask { await self.fetchHeartRate() }
            group.addTask { await self.fetchWeeklySteps() }
            group.addTask { await self.fetchRecentWorkouts() }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func requestAuthorization() async -> Bool {
        return await requestPermissions()
    }
    
    func fetchRecentActivityData() async -> ActivityData? {
        guard isHealthKitAvailable else { return nil }
        
        return ActivityData(
            steps: Int(todaySteps),
            activeCalories: Int(todayCalories),
            calories: Int(todayCalories),
            distance: Double(todaySteps) * 0.0008,
            heartRate: 75.0,
            date: Date()
        )
    }
    
    func fetchRecentWorkoutsData() async -> [WorkoutData] {
        guard isHealthKitAvailable else { return [] }
        
        return [
            WorkoutData(
                activityType: "traditionalStrengthTraining",
                name: "Entrenamiento de Fuerza",
                duration: 3600,
                totalEnergyBurned: 300,
                totalDistance: nil,
                calories: 300,
                date: Date(),
                type: "Strength",
                startDate: Date().addingTimeInterval(-3600)
            )
        ]
    }
}
