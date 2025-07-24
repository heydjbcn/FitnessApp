//
//  TimerView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var watchConnectivity = WatchConnectivityManager.instance

    var body: some View {
        VStack(spacing: 16) {
            // Watch status indicator
            if watchConnectivity.isWatchConnected {
                HStack {
                    Image(systemName: "applewatch")
                        .foregroundColor(.green)
                    Text("Sincronizado con Apple Watch")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal)
            }
            
            HStack {
                ZStack {
                    Circle().stroke(AppColors.secondaryGray, lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.timeRemaining) / CGFloat(viewModel.currentTimerDuration))
                        .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: viewModel.timeRemaining)
                    Text(timeString)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                .frame(width: 60, height: 60)
                
                Text("Descanso")
                    .font(AppFonts.body.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Spacer()
                
                Button("Parar") {
                    HapticManager.shared.buttonTapped()
                    viewModel.stopTimer()
                    
                    // Solo finalizar entrenamiento en Apple Watch en dispositivos reales
                    #if !targetEnvironment(simulator)
                    if watchConnectivity.isWatchConnected {
                        watchConnectivity.endWorkoutOnWatch()
                    }
                    #endif
                    
                    // Entrenamiento completado
                    print("✅ Entrenamiento completado")
                }
                .foregroundColor(AppColors.primary)
            }
            .padding()
            
            // Spotify Player Integration
            SpotifyPlayerView()
                .padding(.horizontal)
        }
        .onAppear {
            // Solo iniciar entrenamiento en Apple Watch en dispositivos reales
            #if !targetEnvironment(simulator)
            if watchConnectivity.isWatchConnected {
                startWorkoutOnWatch()
            }
            #endif
        }
    }
    
    private var timeString: String {
        let m = viewModel.timeRemaining / 60
        let s = viewModel.timeRemaining % 60
        return String(format: "%d:%02d", m, s)
    }
    
    private func startWorkoutOnWatch() {
        // Iniciar entrenamiento en Apple Watch (sin HealthKit)
        watchConnectivity.startWorkoutOnWatch()
    }
}
