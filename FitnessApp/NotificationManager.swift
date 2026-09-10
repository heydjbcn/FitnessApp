//
//  NotificationManager.swift
//  ChamaFit
//
//  Avisos locales: fin de descanso. El permiso se pide la primera vez que
//  hace falta (primer descanso), no al abrir la app.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let restId = "rest-timer"

    /// Pide permiso solo si nunca se ha decidido. Si el usuario dijo que no,
    /// no insiste: el descanso sigue funcionando dentro de la app.
    func ensurePermission() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    func scheduleRestNotification(after seconds: TimeInterval) {
        let defaults = UserDefaults.standard
        // Avisos apagados desde la hoja de Notificaciones: no se programa nada.
        guard defaults.object(forKey: "NotificationsEnabled") as? Bool ?? true else { return }

        let content = UNMutableNotificationContent()
        content.title = "¡Descanso terminado!"
        content.body = "A por la siguiente serie."
        // "Modo de enfoque automático": el aviso llega, pero sin sonido ni
        // vibración y sin encender la pantalla (nivel pasivo).
        if defaults.bool(forKey: "autoFocusMode") {
            content.sound = nil
            content.interruptionLevel = .passive
        } else {
            content.sound = .default
            content.interruptionLevel = .timeSensitive
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: restId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelRestNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [restId])
        center.removeDeliveredNotifications(withIdentifiers: [restId])
    }

    /// Limpia el globo del icono y los avisos ya entregados al volver a la app.
    func clearDelivered() {
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.setBadgeCount(0)
    }
}
