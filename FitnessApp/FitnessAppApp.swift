import SwiftUI

@main
struct FitnessAppApp: App {
    @StateObject var workoutViewModel = WorkoutViewModel()
    @StateObject var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .environmentObject(workoutViewModel)
            .environmentObject(themeManager)
            .preferredColorScheme(.dark)
            .onAppear {
                NotificationManager.shared.requestNotificationPermission()
                NotificationManager.shared.syncBadgeWithNotificationStore()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                NotificationManager.shared.syncBadgeWithNotificationStore()
            }
            .onOpenURL { url in
                print("📱 URL recibida en FitnessAppApp: \(url)")
                // Carga perezosa del SpotifyManager solo cuando se necesite
                Task { @MainActor in
                    SpotifyManager.shared.handleURL(url)
                }
            }
        }
    }
}