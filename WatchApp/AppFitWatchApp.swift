//
//  AppFitWatchApp.swift
//  AppFit Watch App (target watchOS)
//
//  Punto de entrada de la app del Apple Watch.
//

import SwiftUI

@main
struct AppFitWatchApp: App {
    @StateObject private var sync = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(sync)
        }
    }
}
