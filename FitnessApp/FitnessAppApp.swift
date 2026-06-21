import SwiftUI

@main
struct FitnessAppApp: App {
    @StateObject var workoutViewModel = WorkoutViewModel()

    init() {
        FontLoader.registerFonts()
    }

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
            }
        }
    }
}
