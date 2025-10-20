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
    
    init(onNavigateToBestDay: @escaping (WorkoutDay) -> Void, onNavigateToExercises: @escaping () -> Void) {
        self.onNavigateToBestDay = onNavigateToBestDay
        self.onNavigateToExercises = onNavigateToExercises
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                icon: "flame.fill",
                iconColor: AppColors.danger,
                title: "Racha",
                value: "\(viewModel.consecutiveWorkoutDays())",
                subtitle: "días seguidos",
                onTap: nil
            )
            
            StatCard(
                icon: "trophy.fill",
                iconColor: AppColors.primary(themeManager: themeManager),
                title: "Mejor día",
                value: bestDayName(),
                subtitle: "\(Int(bestDayProgress() * 100))% completado",
                onTap: {
                    if let bestDay = viewModel.bestWorkoutDay() {
                        onNavigateToBestDay(bestDay)
                    }
                }
            )
            
            StatCard(
                icon: "list.bullet",
                iconColor: AppColors.accentCyan,
                title: "Ejercicios",
                value: "\(viewModel.totalUniqueExercises())",
                subtitle: "únicos",
                onTap: onNavigateToExercises
            )
            
            StatCard(
                icon: "clock.fill",
                iconColor: AppColors.success,
                title: "Tiempo",
                value: "\(viewModel.estimatedWeeklyWorkoutTime())",
                subtitle: "min semanales",
                onTap: nil
            )
        }
    }
    
    private func bestDayName() -> String {
        guard let bestDay = viewModel.bestWorkoutDay() else { return "---" }
        switch bestDay {
        case .monday: return "Lun"
        case .tuesday: return "Mar"
        case .wednesday: return "Mié"
        case .thursday: return "Jue"
        case .friday: return "Vie"
        case .saturday: return "Sáb"
        case .sunday: return "Dom"
        }
    }
    
    private func bestDayProgress() -> Double {
        guard let bestDay = viewModel.bestWorkoutDay() else { return 0 }
        return viewModel.progressForDay(bestDay)
    }
}

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    let onTap: (() -> Void)?
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 20))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    
                    Text(value)
                        .font(.title2.bold())
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .frame(height: 120)
            .padding()
            .cardStyle(isDarkMode: themeManager.isDarkMode)
        }
        .disabled(onTap == nil)
        .buttonStyle(PlainButtonStyle())
    }
}
