import SwiftUI

@main
struct FitnessAppApp: App {
    @StateObject var workoutViewModel = WorkoutViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .environmentObject(workoutViewModel)
            .preferredColorScheme(.dark)
            .onAppear {
                // Solicitar permisos de notificaciones al iniciar la app
                NotificationManager.shared.requestNotificationPermission()
                // Sincronizar el badge del icono con el número de notificaciones no leídas
                NotificationManager.shared.syncBadgeWithNotificationStore()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Sincronizar badge cuando la app vuelve del background
                NotificationManager.shared.syncBadgeWithNotificationStore()
            }
        }
    }
}
