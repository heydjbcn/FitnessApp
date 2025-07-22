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
    
    private init() {}
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    func scheduleRestNotification(after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "¡Descanso terminado!"
        content.body = "Es hora de continuar con tu entrenamiento"
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "rest-timer", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                // Agregar también a nuestro store interno
                DispatchQueue.main.async {
                    NotificationStore.shared.addRestTimerNotification()
                }
            }
        }
    }
    
    func cancelRestNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest-timer"])
    }
    
    func scheduleWorkoutReminder(at time: Date, exerciseName: String) {
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
                // Agregar también a nuestro store interno
                DispatchQueue.main.async {
                    NotificationStore.shared.addWorkoutReminder(exerciseName: exerciseName)
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
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func clearApplicationBadge() {
        updateApplicationBadge(count: 0)
    }
    
    // Función para sincronizar el badge con el número real de notificaciones no leídas
    func syncBadgeWithNotificationStore() {
        let unreadCount = NotificationStore.shared.unreadCount
        updateApplicationBadge(count: unreadCount)
    }
}
