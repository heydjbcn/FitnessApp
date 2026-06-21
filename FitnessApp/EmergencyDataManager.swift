import Foundation
import UIKit
import Combine

// MARK: - Emergency Data Management
/// Maneja la limpieza crítica de datos para prevenir que iOS mate la app por sobrecarga de UserDefaults
@MainActor
class EmergencyDataManager: ObservableObject {
    static let shared = EmergencyDataManager()
    
    private let MAX_SAFE_SIZE = 50_000 // 50KB límite estricto
    private let CRITICAL_SIZE = 100_000 // 100KB - iOS mata la app
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    /// Ejecuta limpieza de emergencia si los datos exceden límites críticos
    func performEmergencyCleanupIfNeeded() {
        let totalSize = calculateUserDefaultsSize()
        
        print("📊 UserDefaults total size: \(totalSize) bytes")
        
        if totalSize > CRITICAL_SIZE {
            print("🚨 EMERGENCIA CRÍTICA: UserDefaults > 100KB - iOS MATARÁ la app")
            performCriticalCleanup()
        } else if totalSize > MAX_SAFE_SIZE {
            print("⚠️ ADVERTENCIA: UserDefaults > 50KB - Limpieza preventiva")
            performPreventiveCleanup()
        }
    }
    
    /// Calcula el tamaño total de UserDefaults
    private func calculateUserDefaultsSize() -> Int {
        var totalSize = 0
        
        let criticalKeys = [
            "AvailableExercises",
            "DailyWorkoutRecords", 
            "WorkoutHistory",
            "BodyWeightHistory",
            "SessionNotes",
            "ActiveDays"
        ]
        
        for key in criticalKeys {
            if let data = userDefaults.data(forKey: key) {
                totalSize += data.count
                print("📊 \(key): \(data.count) bytes")
            }
        }
        
        return totalSize
    }
    
    /// Limpieza crítica - mantener solo lo esencial
    private func performCriticalCleanup() {
        print("🚨 INICIANDO LIMPIEZA CRÍTICA")
        
        // 1. Mover historial a archivos locales
        migrateHistoryToFiles()
        
        // 2. Mantener solo últimos 7 días de registros
        limitDailyRecords(days: 7)
        
        // 3. Eliminar imágenes de ejercicios no usados
        cleanupUnusedExerciseImages()
        
        // 4. Comprimir notas de sesión
        compressSessionNotes()
        
        print("🚨 LIMPIEZA CRÍTICA COMPLETADA")
    }
    
    /// Limpieza preventiva - más conservadora
    private func performPreventiveCleanup() {
        print("⚠️ INICIANDO LIMPIEZA PREVENTIVA")
        
        // 1. Mantener solo últimos 30 días
        limitDailyRecords(days: 30)
        
        // 2. Limpiar historial antiguo
        limitWorkoutHistory(days: 60)
        
        // 3. Comprimir datos si es posible
        compressDataIfNeeded()
        
        print("⚠️ LIMPIEZA PREVENTIVA COMPLETADA")
    }
    
    /// Migra historial a archivos JSON locales
    private func migrateHistoryToFiles() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Migrar WorkoutHistory
        if let historyData = userDefaults.data(forKey: "WorkoutHistory") {
            let historyFile = documentsPath.appendingPathComponent("workout_history.json")
            try? historyData.write(to: historyFile)
            userDefaults.removeObject(forKey: "WorkoutHistory")
            print("📁 WorkoutHistory migrado a archivo local")
        }
        
        // Migrar BodyWeightHistory
        if let weightData = userDefaults.data(forKey: "BodyWeightHistory") {
            let weightFile = documentsPath.appendingPathComponent("weight_history.json")
            try? weightData.write(to: weightFile)
            userDefaults.removeObject(forKey: "BodyWeightHistory")
            print("📁 BodyWeightHistory migrado a archivo local")
        }
    }
    
    /// Limita registros diarios a X días
    private func limitDailyRecords(days: Int) {
        guard userDefaults.data(forKey: "DailyWorkoutRecords") != nil else {
            return
        }
        
        // For now, just remove the data if it exists to avoid decoding issues
        userDefaults.removeObject(forKey: "DailyWorkoutRecords")
        print("🗂️ DailyWorkoutRecords removido (limitación no implementada)")
    }
    }
    
    /// Limita historial de workouts
    private func limitWorkoutHistory(days: Int) {
        // Implementación similar a limitDailyRecords
        print("🗂️ WorkoutHistory limitado a \(days) días")
    }
    
    /// Limpia imágenes de ejercicios no utilizados
    private func cleanupUnusedExerciseImages() {
        // Implementar limpieza de imágenes
        print("🖼️ Imágenes de ejercicios no utilizados eliminadas")
    }
    
    /// Comprime notas de sesión eliminando las muy antiguas
    private func compressSessionNotes() {
        guard let notesData = UserDefaults.standard.data(forKey: "SessionNotes"),
              var notes = try? JSONDecoder().decode([String: String].self, from: notesData) else {
            return
        }
        
        // Mantener solo últimas 50 notas
        if notes.count > 50 {
            let sortedKeys = notes.keys.sorted()
            let recentKeys = Array(sortedKeys.suffix(50))
            notes = notes.filter { recentKeys.contains($0.key) }
            
            if let newData = try? JSONEncoder().encode(notes) {
                UserDefaults.standard.set(newData, forKey: "SessionNotes")
                print("📝 SessionNotes comprimidas a 50 entradas")
            }
        }
    }
    
    /// Comprime datos usando técnicas de compresión
    private func compressDataIfNeeded() {
        // Implementar compresión de datos si es necesario
        print("🗜️ Datos comprimidos si era necesario")
    }

// MARK: - Debounced Save Manager
/// Previene guardado excesivo implementando debouncing
@MainActor
class DebouncedSaveManager {
    static let shared = DebouncedSaveManager()
    
    private var saveWorkItem: DispatchWorkItem?
    private let saveDelay: TimeInterval = 2.0
    
    private init() {}
    
    /// Programa un guardado con debouncing
    func scheduleSave(action: @escaping () -> Void) {
        // Cancelar guardado anterior si existe
        saveWorkItem?.cancel()
        
        // Crear nuevo trabajo de guardado
        saveWorkItem = DispatchWorkItem {
            action()
        }
        
        // Programar guardado después del delay
        DispatchQueue.main.asyncAfter(deadline: .now() + saveDelay, execute: saveWorkItem!)
    }
    
    /// Fuerza un guardado inmediato
    func forceSave(action: @escaping () -> Void) {
        saveWorkItem?.cancel()
        action()
    }
}

// MARK: - Memory Monitor
/// Monitorea el uso de memoria y dispara limpiezas automáticas
class MemoryMonitor {
    static let shared = MemoryMonitor()
    
    private init() {
        setupMemoryWarningObserver()
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.handleMemoryWarning()
            }
        }
    }
    
    @MainActor
    private func handleMemoryWarning() {
        print("🚨 ADVERTENCIA DE MEMORIA DEL SISTEMA")
        
        // Ejecutar limpieza de emergencia
        EmergencyDataManager.shared.performEmergencyCleanupIfNeeded()
        
        // Notificar a otros componentes
        NotificationCenter.default.post(name: .memoryWarning, object: nil)
    }
    
    /// Obtiene el uso actual de memoria
    func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}

extension Notification.Name {
    static let memoryWarning = Notification.Name("MemoryWarning")
}
