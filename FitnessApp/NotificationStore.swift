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
