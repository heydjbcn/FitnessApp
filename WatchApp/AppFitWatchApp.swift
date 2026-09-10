//
//  AppFitWatchApp.swift
//  ChamaFit Watch (target watchOS)
//
//  Punto de entrada de la app del Apple Watch.
//

import SwiftUI

@main
struct ChamaFitWatchApp: App {
    @StateObject private var sync = WatchConnectivityManager.shared
    @StateObject private var workout = WorkoutSessionManager.shared

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(sync)
                .environmentObject(workout)
        }
    }
}
