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
import Foundation
import Combine

struct AppNotification: Identifiable, Codable {
    var id = UUID()
    let title: String
    let message: String
    let timestamp: Date
    let type: NotificationType
    var isRead: Bool = false
    
    enum NotificationType: String, Codable, CaseIterable {
        case workoutReminder = "workout_reminder"
        case restTimer = "rest_timer"
        case achievement = "achievement"
        case general = "general"
        
        var icon: String {
            switch self {
            case .workoutReminder: return "alarm.fill"
            case .restTimer: return "timer"
            case .achievement: return "trophy.fill"
            case .general: return "bell.fill"
            }
        }
        
        var color: String {
            switch self {
            case .workoutReminder: return "blue"
            case .restTimer: return "orange"
            case .achievement: return "yellow"
            case .general: return "gray"
            }
        }
    }
}
//
//  NotificationStore.swift
//  FitnessApp
//
//  Created by Assistant on 22/7/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - NotificationStore
class NotificationStore: ObservableObject {
    static let shared = NotificationStore()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let notificationsKey = "app_notifications"
    
    private init() {
        loadNotifications()
    }
    
    // MARK: - Load/Save
    private func loadNotifications() {
        if let data = userDefaults.data(forKey: notificationsKey) {
            do {
                let decoded = try JSONDecoder().decode([AppNotification].self, from: data)
                self.notifications = decoded.sorted { $0.timestamp > $1.timestamp }
                updateUnreadCount()
                print("✅ NOTIFICATION_STORE: Se cargaron \(self.notifications.count) notificaciones. No leídas: \(self.unreadCount)")
            } catch {
                print("Error loading notifications: \(error)")
                self.notifications = []
                self.unreadCount = 0 // ✨ FIX: Resetear contador cuando falla la carga
                print("❌ NOTIFICATION_STORE: Error al cargar notificaciones. Lista y contador reseteados.")
            }
        } else {
            print("✅ NOTIFICATION_STORE: No hay notificaciones guardadas. Lista vacía.")
        }
    }
    
    private func saveNotifications() {
        do {
            let encoded = try JSONEncoder().encode(notifications)
            userDefaults.set(encoded, forKey: notificationsKey)
        } catch {
            print("Error saving notifications: \(error)")
        }
    }
    
    // MARK: - Add Notifications
    func addWorkoutReminder(exerciseName: String) {
        let notification = AppNotification(
            title: "💪 Recordatorio de Ejercicio",
            message: "¡Es hora de hacer \(exerciseName)!",
            timestamp: Date(),
            type: .workoutReminder
        )
        addNotification(notification)
    }
    
    func addRestTimerNotification() {
        let notification = AppNotification(
            title: "⏰ Descanso Terminado",
            message: "¡Tu tiempo de descanso ha terminado! Continúa con tu entrenamiento.",
            timestamp: Date(),
            type: .restTimer
        )
        addNotification(notification)
    }
    
    func addAchievement(message: String) {
        let notification = AppNotification(
            title: "🏆 ¡Logro Desbloqueado!",
            message: message,
            timestamp: Date(),
            type: .achievement
        )
        addNotification(notification)
    }
    
    func addReminder(title: String, message: String) {
        let notification = AppNotification(
            title: title,
            message: message,
            timestamp: Date(),
            type: .general
        )
        addNotification(notification)
    }
    
    private func addNotification(_ notification: AppNotification) {
        DispatchQueue.main.async {
            self.notifications.insert(notification, at: 0)
            self.updateUnreadCount()
            self.saveNotifications()
        }
    }
    
    // MARK: - Mark as Read
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            updateUnreadCount()
            saveNotifications()
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
        saveNotifications()
    }
    
    // MARK: - Helper Methods
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
        // Sincronizar el badge del icono de la aplicación
        NotificationManager.shared.updateApplicationBadge(count: unreadCount)
    }
    
    func clearAll() {
        print("❌ NOTIFICATION_STORE: ¡Se ha llamado a clearAll! Se van a borrar \(notifications.count) notificaciones.")
        // Añadir stack trace para ver quién llama a esta función
        print("📍 STACK TRACE: \(Thread.callStackSymbols.prefix(5).joined(separator: "\n"))")
        notifications.removeAll()
        unreadCount = 0
        saveNotifications()
        // Limpiar el badge del icono de la aplicación
        NotificationManager.shared.clearApplicationBadge()
    }
    
    // MARK: - Delete Notification
    func deleteNotification(_ notification: AppNotification) {
        notifications.removeAll { $0.id == notification.id }
        updateUnreadCount()
        saveNotifications()
    }
}
