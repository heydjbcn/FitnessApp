import SwiftUI

@main
struct FitnessAppApp: App {
    // Dueños únicos del estado: ContentView los consume por @EnvironmentObject.
    // Antes ContentView creaba los suyos propios y la app cargaba los datos dos veces.
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var userManager = UserManager()

    init() {
        FontLoader.registerFonts()
        // Solo actúa en una pasada de pruebas (dominio de datos aparte).
        AppDefaults.applyLaunchArguments()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .environmentObject(workoutViewModel)
            .environmentObject(themeManager)
            .environmentObject(userManager)
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            // La vuelta de Spotify tras autorizar (chamafit-spotify://callback)
            .onOpenURL { url in
                if url.scheme == "chamafit-spotify" { SpotifyManager.shared.handle(url: url) }
            }
        }
    }
}
