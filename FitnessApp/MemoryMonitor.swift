//
//  MemoryMonitor.swift
//  FitnessApp
//
//  Created by Assistant - Memory Optimization
//

import Foundation
import UIKit

class MemoryMonitor {
    static let shared = MemoryMonitor()
    
    private var monitoringTimer: Timer?
    private let memoryThreshold: UInt64 = 100 * 1024 * 1024 // 100MB
    
    private init() {}
    
    func startMonitoring() {
        // Solo monitorear en dispositivos reales, no en simulador
        #if !targetEnvironment(simulator)
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            self.checkMemoryUsage()
        }
        print("🧠 MemoryMonitor: Monitoreo iniciado (dispositivo real)")
        #else
        print("🧠 MemoryMonitor: Saltando monitoreo en simulador")
        #endif
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        print("🧠 MemoryMonitor: Monitoreo detenido")
    }
    
    private func checkMemoryUsage() {
        let memoryUsage = getCurrentMemoryUsage()
        let memoryUsageMB = memoryUsage / (1024 * 1024)
        
        // Solo log cada 30 segundos para no saturar la consola
        if Int(Date().timeIntervalSince1970) % 30 == 0 {
            print("🧠 Memoria actual: \(memoryUsageMB) MB")
        }
        
        if memoryUsage > memoryThreshold {
            print("⚠️ ADVERTENCIA: Uso alto de memoria - \(memoryUsageMB) MB")
            
            // Notificar para limpieza
            NotificationCenter.default.post(name: .memoryWarning, object: memoryUsageMB)
            
            // Forzar limpieza de memoria
            triggerMemoryCleanup()
        }
    }
    
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
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
    
    private func triggerMemoryCleanup() {
        DispatchQueue.main.async {
            // Forzar liberación de memoria del sistema
            URLCache.shared.removeAllCachedResponses()
            
            // Liberar caché de imágenes si hay alguno
            URLCache.shared.diskCapacity = 0
            URLCache.shared.memoryCapacity = 0
            
            // Notificar a ViewModels para que limpien
            NotificationCenter.default.post(name: .shouldCleanupMemory, object: nil)
            
            print("🧹 MemoryMonitor: Limpieza de memoria activada")
        }
    }
    
    // Método público para forzar verificación de memoria
    func forceMemoryCheck() {
        checkMemoryUsage()
    }
    
    // Método para obtener uso actual de memoria (público)
    func getCurrentMemoryUsageMB() -> UInt64 {
        return getCurrentMemoryUsage() / (1024 * 1024)
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let memoryWarning = Notification.Name("memoryWarning")
    static let shouldCleanupMemory = Notification.Name("shouldCleanupMemory")
}
