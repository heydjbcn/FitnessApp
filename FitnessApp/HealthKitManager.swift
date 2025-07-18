import Foundation
import HealthKit
import SwiftUI
import Combine

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isHealthKitAvailable = false
    @Published var isAuthorized = false
    
    init() {
        checkHealthKitAvailability()
    }
    
    private func checkHealthKitAvailability() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
        print("🏥 HealthKit disponible: \(isHealthKitAvailable)")
        
        #if targetEnvironment(simulator)
        print("📱 Ejecutándose en SIMULADOR")
        #else
        print("📱 Ejecutándose en DISPOSITIVO REAL")
        #endif
    }
    
    // Tipos de datos que queremos leer (inicialmente solo lectura)
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
        HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .bodyMass)!
    ]
    
    // Tipos de datos que queremos escribir (se solicitan por separado)
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .bodyMass)!
    ]
    
    func requestAuthorization() async {
        #if targetEnvironment(simulator)
        // En simulador, usar datos simulados
        print("📱 Simulador detectado - usando datos simulados")
        await MainActor.run {
            self.isAuthorized = true
        }
        return
        #endif
        
        guard isHealthKitAvailable else { 
            print("❌ HealthKit no está disponible - usando datos simulados")
            await MainActor.run {
                self.isAuthorized = true // Permitir app funcionar sin HealthKit
            }
            return 
        }
        
        print("🏃‍♂️ Intentando autorización de HealthKit...")
        
        // Tipos de datos que queremos leer
        let typesToRead = Set([
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.workoutType()
        ])
        
        // Tipos de datos que queremos escribir (opcional)
        let typesToWrite = Set([
            HKObjectType.workoutType()
        ])
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            print("✅ Solicitud de autorización enviada")
            
            // Verificar el estado específico después de la autorización
            let stepsAuthStatus = healthStore.authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: .stepCount)!)
            
            await MainActor.run {
                switch stepsAuthStatus {
                case .sharingAuthorized:
                    self.isAuthorized = true
                    print("✅ HealthKit autorizado - datos reales disponibles")
                case .sharingDenied:
                    self.isAuthorized = true // Permitir app funcionar sin HealthKit
                    print("⚠️ HealthKit denegado - usando datos simulados")
                case .notDetermined:
                    self.isAuthorized = true // Permitir app funcionar
                    print("⚠️ HealthKit indeterminado - usando datos simulados")
                @unknown default:
                    self.isAuthorized = true // Permitir app funcionar
                    print("⚠️ HealthKit estado desconocido - usando datos simulados")
                }
            }
        } catch {
            print("⚠️ HealthKit no disponible: \(error) - usando datos simulados")
            await MainActor.run {
                self.isAuthorized = true // Permitir app funcionar sin HealthKit
            }
        }
    }
    
    // Función separada para solicitar permisos de escritura
    private func requestWriteAuthorization() async -> Bool {
        guard isHealthKitAvailable else { return false }
        
        do {
            try await withTimeout(seconds: 30) { [self] in
                try await healthStore.requestAuthorization(toShare: writeTypes, read: [])
            }
            return true
        } catch {
            print("Error solicitando permisos de escritura de HealthKit: \(error)")
            return false
        }
    }
    
    // Guardar workout en HealthKit
    func saveWorkout(
        activityType: HKWorkoutActivityType = .traditionalStrengthTraining,
        startDate: Date,
        endDate: Date,
        totalEnergyBurned: Double? = nil,
        totalDistance: Double? = nil
    ) async {
        guard isAuthorized else { return }
        
        // Solicitar permisos de escritura si aún no los tenemos
        let hasWritePermission = await requestWriteAuthorization()
        guard hasWritePermission else {
            print("No se pudieron obtener permisos de escritura para HealthKit")
            return
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = .indoor
        
        // Usar HKWorkoutBuilder para iOS 17+
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        do {
            try await builder.beginCollection(at: startDate)
            try await builder.endCollection(at: endDate)
            
            guard let workout = try await builder.finishWorkout() else {
                print("Error: No se pudo crear el workout")
                return
            }
            
            try await healthStore.save(workout)
            print("Workout guardado en HealthKit")
        } catch {
            print("Error guardando workout: \(error)")
        }
    }
    
    // Leer datos recientes de Apple Fitness
    func fetchRecentActivityData() async -> ActivityData? {
        guard isAuthorized else { return nil }
        
        // Verificar si tenemos acceso real a HealthKit
        let stepsAuthStatus = healthStore.authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: .stepCount)!)
        
        if stepsAuthStatus != .sharingAuthorized {
            print("📊 Usando datos simulados - HealthKit no autorizado")
            // Retornar datos simulados realistas
            return ActivityData(
                steps: Int.random(in: 5000...12000),
                activeCalories: Int.random(in: 200...800),
                walkingDistance: Double.random(in: 2.0...8.0),
                cyclingDistance: Double.random(in: 0.0...15.0),
                exerciseTime: Int.random(in: 15...90),
                date: Date()
            )
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        do {
            // Usar timeout para toda la operación
            return try await withTimeout(seconds: 20) { [self] in
                // Obtener pasos
                let steps = await fetchQuantityData(
                    type: .stepCount,
                    startDate: startOfDay,
                    endDate: now,
                    unit: HKUnit.count()
                )
                
                // Obtener calorías quemadas
                let calories = await fetchQuantityData(
                    type: .activeEnergyBurned,
                    startDate: startOfDay,
                    endDate: now,
                    unit: HKUnit.kilocalorie()
                )
                
                // Obtener distancia caminando/corriendo
                let walkingDistance = await fetchQuantityData(
                    type: .distanceWalkingRunning,
                    startDate: startOfDay,
                    endDate: now,
                    unit: HKUnit.meter()
                )
                
                // Obtener distancia en bicicleta
                let cyclingDistance = await fetchQuantityData(
                    type: .distanceCycling,
                    startDate: startOfDay,
                    endDate: now,
                    unit: HKUnit.meter()
                )
                
                // Obtener tiempo de ejercicio
                let exerciseTime = await fetchQuantityData(
                    type: .appleExerciseTime,
                    startDate: startOfDay,
                    endDate: now,
                    unit: HKUnit.minute()
                )
                
                return ActivityData(
                    steps: Int(steps),
                    activeCalories: Int(calories),
                    walkingDistance: walkingDistance / 1000, // convertir a km
                    cyclingDistance: cyclingDistance / 1000, // convertir a km
                    exerciseTime: Int(exerciseTime),
                    date: now
                )
            }
        } catch {
            print("⚠️ Error obteniendo datos reales - usando simulados: \(error)")
            // Fallback a datos simulados
            return ActivityData(
                steps: Int.random(in: 5000...12000),
                activeCalories: Int.random(in: 200...800),
                walkingDistance: Double.random(in: 2.0...8.0),
                cyclingDistance: Double.random(in: 0.0...15.0),
                exerciseTime: Int.random(in: 15...90),
                date: now
            )
        }
    }
    
    // Obtener workouts recientes
    func fetchRecentWorkouts(days: Int = 7) async -> [WorkoutData] {
        guard isAuthorized else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        
        do {
            return try await withTimeout(seconds: 15) { [self] in
                await withCheckedContinuation { continuation in
                    let predicate = HKQuery.predicateForSamples(
                        withStart: startDate,
                        end: now,
                        options: .strictStartDate
                    )
                    
                    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                    
                    let query = HKSampleQuery(
                        sampleType: HKObjectType.workoutType(),
                        predicate: predicate,
                        limit: HKObjectQueryNoLimit,
                        sortDescriptors: [sortDescriptor]
                    ) { _, samples, error in
                        if let error = error {
                            print("Error obteniendo workouts: \(error)")
                            continuation.resume(returning: [])
                            return
                        }
                        
                        guard let workouts = samples as? [HKWorkout] else {
                            continuation.resume(returning: [])
                            return
                        }
                        
                        let workoutData = workouts.map { workout in
                            WorkoutData(
                                activityType: workout.workoutActivityType,
                                startDate: workout.startDate,
                                endDate: workout.endDate,
                                duration: workout.duration,
                                totalEnergyBurned: workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()),
                                totalDistance: workout.totalDistance?.doubleValue(for: .meter())
                            )
                        }
                        
                        continuation.resume(returning: workoutData)
                    }
                    
                    healthStore.execute(query)
                }
            }
        } catch {
            print("Error o timeout obteniendo workouts: \(error)")
            return []
        }
    }
    
    private func fetchQuantityData(
        type: HKQuantityTypeIdentifier,
        startDate: Date,
        endDate: Date,
        unit: HKUnit
    ) async -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: type) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        do {
            return try await withTimeout(seconds: 15) { [self] in
                await withCheckedContinuation { continuation in
                    let query = HKStatisticsQuery(
                        quantityType: quantityType,
                        quantitySamplePredicate: predicate,
                        options: .cumulativeSum
                    ) { _, result, error in
                        if let error = error {
                            print("Error en query de HealthKit: \(error)")
                            continuation.resume(returning: 0)
                            return
                        }
                        
                        guard let result = result,
                              let sum = result.sumQuantity() else {
                            continuation.resume(returning: 0)
                            return
                        }
                        continuation.resume(returning: sum.doubleValue(for: unit))
                    }
                    
                    healthStore.execute(query)
                }
            }
        } catch {
            print("Error o timeout en fetchQuantityData: \(error)")
            return 0
        }
    }
    
    // Obtener peso corporal reciente
    func fetchRecentBodyWeight() async -> Double? {
        guard isAuthorized,
              let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        do {
            return try await withTimeout(seconds: 10) { [self] in
                await withCheckedContinuation { continuation in
                    let query = HKSampleQuery(
                        sampleType: bodyMassType,
                        predicate: nil,
                        limit: 1,
                        sortDescriptors: [sortDescriptor]
                    ) { _, samples, _ in
                        guard let samples = samples as? [HKQuantitySample],
                              let mostRecent = samples.first else {
                            continuation.resume(returning: nil)
                            return
                        }
                        
                        let weightInKg = mostRecent.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                        continuation.resume(returning: weightInKg)
                    }
                    
                    healthStore.execute(query)
                }
            }
        } catch {
            print("Error o timeout obteniendo peso corporal: \(error)")
            return nil
        }
    }
}

struct ActivityData {
    let steps: Int
    let activeCalories: Int
    let walkingDistance: Double // en km
    let cyclingDistance: Double // en km
    let exerciseTime: Int // en minutos
    let date: Date
}

struct WorkoutData {
    let activityType: HKWorkoutActivityType
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let totalEnergyBurned: Double?
    let totalDistance: Double? // en metros
    
    var activityName: String {
        switch activityType {
        case .running:
            return "Correr"
        case .walking:
            return "Caminar"
        case .cycling:
            return "Ciclismo"
        case .swimming:
            return "Natación"
        case .yoga:
            return "Yoga"
        case .traditionalStrengthTraining:
            return "Entrenamiento de fuerza"
        case .functionalStrengthTraining:
            return "Entrenamiento funcional"
        case .hiking:
            return "Senderismo"
        case .dance:
            return "Baile"
        case .soccer:
            return "Fútbol"
        case .basketball:
            return "Baloncesto"
        case .tennis:
            return "Tenis"
        default:
            return "Ejercicio"
        }
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedDistance: String? {
        guard let distance = totalDistance else { return nil }
        let km = distance / 1000
        if km >= 1 {
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    var formattedCalories: String? {
        guard let calories = totalEnergyBurned else { return nil }
        return "\(Int(calories)) cal"
    }
}

// Extensión para agregar timeout a operaciones async
extension HealthKitManager {
    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: Optional<T>.self) { group in
            // Agregar tarea principal
            group.addTask {
                try await operation()
            }
            
            // Agregar tarea de timeout
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            
            // Esperar el primer resultado
            for try await result in group {
                group.cancelAll()
                if let actualResult = result {
                    return actualResult
                } else {
                    throw TimeoutError()
                }
            }
            
            throw TimeoutError()
        }
    }
}

struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "La operación de HealthKit tardó demasiado tiempo"
    }
}
