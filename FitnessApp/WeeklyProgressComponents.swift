//
//  WeeklyProgressView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import SwiftUI

struct WeeklyProgressView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progreso Semanal")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            
            HStack(spacing: 20) {
                // Círculo de progreso semanal
                ZStack {
                    Circle()
                        .stroke(AppColors.secondaryGray.opacity(0.3), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0, to: viewModel.weeklyProgress())
                        .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: viewModel.weeklyProgress())
                    
                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.weeklyProgress() * 100))%")
                            .font(.headline.bold())
                            .foregroundColor(AppColors.primary)
                        Text("completado")
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(AppColors.primary)
                        Text("\(viewModel.weeklyCompletedSets())/\(viewModel.weeklyTotalSets()) series")
                            .font(.body)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(AppColors.danger)
                        Text("\(viewModel.consecutiveWorkoutDays()) días seguidos")
                            .font(.body)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(AppColors.accentCyan)
                        Text("\(viewModel.estimatedWeeklyWorkoutTime()) min esta semana")
                            .font(.body)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                }
                Spacer()
            }
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
}

struct WeeklyExercisesList: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ejercicios de la Semana")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            
            let weeklyExercises = viewModel.weeklyExercisesSummary()
            
            if weeklyExercises.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.5))
                    Text("No hay ejercicios programados")
                        .font(.body)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    Text("Agrega ejercicios desde Configuración")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(weeklyExercises, id: \.day) { dayData in
                        WeeklyDayRow(day: dayData.day, exercises: dayData.exercises)
                    }
                }
            }
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
}

struct WeeklyDayRow: View {
    let day: WorkoutDay
    let exercises: [Exercise]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dayName(for: day))
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Spacer()
                
                Text("\(exercises.reduce(0) { $0 + $1.completedSets })/\(exercises.reduce(0) { $0 + $1.totalSets })")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.secondaryGray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(exercises, id: \.id) { exercise in
                    WeeklyExerciseItem(exercise: exercise)
                }
            }
        }
        .padding()
        .background(AppColors.background(isDark: themeManager.isDarkMode))
        .cornerRadius(8)
    }
    
    private func dayName(for day: WorkoutDay) -> String {
        switch day {
        case .monday: return "Lunes"
        case .tuesday: return "Martes"
        case .wednesday: return "Miércoles"
        case .thursday: return "Jueves"
        case .friday: return "Viernes"
        }
    }
}

struct WeeklyExerciseItem: View {
    let exercise: Exercise
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: exercise.completedSets >= exercise.totalSets ? "checkmark.circle.fill" : "circle")
                .foregroundColor(exercise.completedSets >= exercise.totalSets ? AppColors.success : AppColors.textSecondary(isDark: themeManager.isDarkMode))
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.caption)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    .lineLimit(1)
                
                Text("\(exercise.completedSets)/\(exercise.totalSets) × \(exercise.repetitions)")
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(6)
    }
}
