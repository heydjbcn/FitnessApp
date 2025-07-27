//
//  NotificationManager.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 18/7/25.
//

import Foundation
import UserNotifications
import Combine
import UIKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    // Estado para evitar notificaciones duplicadas
    private var lastNotificationTime: Date?
    private let minimumTimeBetweenNotifications: TimeInterval = 2.0 // 2 segundos mínimo
    
    private init() {}
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    func scheduleRestNotification(after seconds: TimeInterval) {
        // Verificar si las notificaciones están habilitadas
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") != false else {
            print("NotificationManager: Notificaciones desactivadas por el usuario")
            return
        }
        
        // Evitar notificaciones duplicadas con tiempo mínimo más alto
        let now = Date()
        if let lastTime = lastNotificationTime,
           now.timeIntervalSince(lastTime) < 5.0 { // Aumentado a 5 segundos
            print("NotificationManager: Evitando notificación duplicada - última: \(lastTime), ahora: \(now)")
            return
        }
        
        // Verificar que el tiempo sea razonable
        guard seconds > 0 && seconds <= 600 else { // Máximo 10 minutos
            print("NotificationManager: Tiempo de notificación inválido: \(seconds)")
            return
        }
        
        // Cancelar notificaciones pendientes del timer
        cancelRestNotification()
        
        let content = UNMutableNotificationContent()
        content.title = "¡Descanso terminado!"
        content.body = "Es hora de continuar con tu entrenamiento"
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "rest-timer-\(Int(now.timeIntervalSince1970))", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("NotificationManager: Notificación programada para \(seconds) segundos")
                // Marcar el tiempo de la última notificación
                DispatchQueue.main.async {
                    self.lastNotificationTime = now
                }
                
                // Agregar también a nuestro store interno SOLO si las notificaciones están activas
                DispatchQueue.main.async {
                    if UserDefaults.standard.bool(forKey: "notificationsEnabled") != false {
                        NotificationStore.shared.addRestTimerNotification()
                    }
                }
            }
        }
    }
    
    func cancelRestNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest-timer"])
    }
    
    func scheduleWorkoutReminder(at time: Date, exerciseName: String) {
        // Verificar si las notificaciones están habilitadas
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") != false else {
            print("NotificationManager: Notificaciones desactivadas por el usuario")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "¡Hora de entrenar!"
        content.body = "No olvides hacer tu ejercicio: \(exerciseName)"
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "workout-reminder-\(exerciseName)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling workout reminder: \(error)")
            } else {
                // Agregar también a nuestro store interno SOLO si las notificaciones están activas
                DispatchQueue.main.async {
                    if UserDefaults.standard.bool(forKey: "notificationsEnabled") != false {
                        NotificationStore.shared.addWorkoutReminder(exerciseName: exerciseName)
                    }
                }
            }
        }
    }
    
    func cancelWorkoutReminder(for exerciseName: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["workout-reminder-\(exerciseName)"])
    }
    
    // MARK: - Badge Management
    func updateApplicationBadge(count: Int) {
        DispatchQueue.main.async {
            if #available(iOS 16.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(count)
            } else {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }
    
    func clearApplicationBadge() {
        updateApplicationBadge(count: 0)
    }
    
    // Función para sincronizar el badge con el número real de notificaciones no leídas
    func syncBadgeWithNotificationStore() {
        // Solo actualizar badge si las notificaciones están habilitadas
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") != false else {
            clearApplicationBadge()
            return
        }
        
        let unreadCount = NotificationStore.shared.unreadCount
        updateApplicationBadge(count: unreadCount)
    }
    
    // MARK: - Métodos para respetar la configuración del usuario
    func areNotificationsEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "notificationsEnabled") != false
    }
    
    func setNotificationsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")
        
        if !enabled {
            // Si se desactivan, cancelar todas las notificaciones pendientes
            cancelAllPendingNotifications()
            clearApplicationBadge()
        }
    }
    
    private func cancelAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("NotificationManager: Todas las notificaciones pendientes han sido canceladas")
    }
}
