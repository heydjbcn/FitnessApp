//
//  StatsCardsView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import SwiftUI

struct StatsCardsView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    let onNavigateToBestDay: (WorkoutDay) -> Void
    let onNavigateToExercises: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Racha
            StatCard(
                icon: "flame.fill",
                value: "\(viewModel.consecutiveWorkoutDays())",
                valueSuffix: "días",
                title: "Racha",
                onTap: nil
            )

            // Mejor día
            StatCard(
                icon: "trophy.fill",
                value: bestDayName(),
                valueSuffix: nil,
                title: "Mejor día",
                onTap: {
                    if let bestDay = viewModel.bestWorkoutDay() {
                        onNavigateToBestDay(bestDay)
                    }
                }
            )

            // Ejercicios
            StatCard(
                icon: "dumbbell.fill",
                value: "\(viewModel.totalUniqueExercises())",
                valueSuffix: nil,
                title: "Ejercicios",
                onTap: onNavigateToExercises
            )
        }
    }

    private func bestDayName() -> String {
        guard let bestDay = viewModel.bestWorkoutDay() else { return "---" }
        return bestDay.shortLabel
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let valueSuffix: String?
    let title: String
    let onTap: (() -> Void)?
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.primary(themeManager: themeManager))

                Spacer(minLength: 0)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(AppFonts.metric)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if let suffix = valueSuffix {
                        Text(suffix)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                }

                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 96)
            .padding(14)
            .cardStyle(isDarkMode: themeManager.isDarkMode)
        }
        .disabled(onTap == nil)
        .buttonStyle(PlainButtonStyle())
    }
}
