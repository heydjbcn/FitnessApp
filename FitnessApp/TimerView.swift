//
//  TimerView.swift - VERSIÓN CORREGIDA SIN ERRORES
//  FitnessApp
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 16) {
            // Timer display section
            HStack {
                ZStack {
                    Circle().stroke(AppColors.secondaryGray, lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(AppColors.primary(themeManager: themeManager), style: StrokeStyle(lineWidth: 4, lineCap: .round))
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
                    viewModel.stopTimer()
                }
                .foregroundColor(.red)
                .font(AppFonts.caption.weight(.semibold))
            }
            .padding(.horizontal)
            
            // Timer controls
            HStack(spacing: 20) {
                Button(action: {
                    if viewModel.isTimerRunning {
                        viewModel.pauseTimer()
                    } else {
                        viewModel.resumeTimer()
                    }
                }) {
                    Image(systemName: viewModel.isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
                
                Button(action: {
                    viewModel.resetTimer()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                Button(action: {
                    viewModel.addTime(30)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("30s")
                    }
                    .font(.caption)
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // ✅ CORREGIDO: Cálculo del progreso
    private var progressValue: CGFloat {
        guard viewModel.currentTimerDuration > 0 else { return 0 }
        return CGFloat(viewModel.timeRemaining) / CGFloat(viewModel.currentTimerDuration)
    }
    
    private var timeString: String {
        let totalSeconds = Int(viewModel.timeRemaining)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
            .environmentObject(WorkoutViewModel())
            .environmentObject(ThemeManager())
    }
}
