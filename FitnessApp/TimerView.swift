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

    var body: some View {
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
            }
            .foregroundColor(AppColors.primary)
        }
        .padding()
    }
    
    private var timeString: String {
        let m = viewModel.timeRemaining / 60
        let s = viewModel.timeRemaining % 60
        return String(format: "%d:%02d", m, s)
    }
}
