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
        }
    }
}
