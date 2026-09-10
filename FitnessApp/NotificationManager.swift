//
//  NotificationManager.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 18/7/25.
//

import Foundation
import UserNotifications
import Combine

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
        let defaults = UserDefaults.standard
        // Avisos apagados desde la hoja de Notificaciones: no se programa nada.
        guard defaults.object(forKey: "NotificationsEnabled") as? Bool ?? true else { return }

        let content = UNMutableNotificationContent()
        content.title = "¡Descanso terminado!"
        content.body = "Es hora de continuar con tu entrenamiento"
        // "Modo de enfoque automático": el aviso llega, pero sin sonido ni
        // vibración y sin encender la pantalla (nivel pasivo).
        if defaults.bool(forKey: "autoFocusMode") {
            content.sound = nil
            content.interruptionLevel = .passive
        } else {
            content.sound = UNNotificationSound.default
        }
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "rest-timer", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
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
            }
        }
    }
    
    func cancelWorkoutReminder(for exerciseName: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["workout-reminder-\(exerciseName)"])
    }
}
