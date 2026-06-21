//
//  AppleFitnessCard.swift
//  FitnessApp
//
//  Vista estilo Apple Fitness para mostrar el progreso
//

import SwiftUI

struct AppleFitnessCard: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Progreso de Hoy")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Spacer()
                
                Text("\(Int(todayProgress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
            }
            
            // Anillos de progreso estilo Apple Fitness
            HStack(spacing: 20) {
                // Anillo principal - Ejercicios completados
                FitnessRing(
                    progress: todayProgress,
                    color: AppColors.primary(themeManager: themeManager),
                    lineWidth: 8,
                    size: 80
                )
                .overlay(
                    VStack(spacing: 2) {
                        Text("\(completedTodayExercises)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        Text("ejercicios")
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                )
                
                VStack(alignment: .leading, spacing: 12) {
                    // Serie completadas
                    FitnessMetric(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: "Series",
                        value: "\(completedTodaySets)",
                        subtitle: "de \(totalTodaySets)",
                        themeManager: themeManager
                    )
                    
                    // Tiempo activo
                    FitnessMetric(
                        icon: "clock.fill",
                        color: .orange,
                        title: "Tiempo",
                        value: "\(activeTimeToday)m",
                        subtitle: "activo",
                        themeManager: themeManager
                    )
                }
                
                Spacer()
            }
            
            // Progreso semanal compacto
            VStack(alignment: .leading, spacing: 8) {
                Text("Esta Semana")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                HStack(spacing: 4) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                        WeekDayIndicator(
                            day: day.short,
                            isCompleted: weekCompletionStatus[index],
                            isToday: index == todayIndex,
                            themeManager: themeManager
                        )
                    }
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Computed Properties
    private var todayProgress: Double {
        guard totalTodaySets > 0 else { return 0 }
        return Double(completedTodaySets) / Double(totalTodaySets)
    }
    
    private var completedTodayExercises: Int {
        guard let today = WorkoutDay.from(date: Date()) else { return 0 }
        return viewModel.dailyWorkoutRecords[today]?.filter { $0.isCompleted }.count ?? 0
    }
    
    private var completedTodaySets: Int {
        guard let today = WorkoutDay.from(date: Date()) else { return 0 }
        return viewModel.dailyWorkoutRecords[today]?.reduce(0) { $0 + $1.completedSets } ?? 0
    }
    
    private var totalTodaySets: Int {
        guard let today = WorkoutDay.from(date: Date()) else { return 0 }
        return viewModel.dailyWorkoutRecords[today]?.reduce(0) { $0 + $1.totalSets } ?? 0
    }
    
    private var activeTimeToday: Int {
        // Estimación basada en series completadas (2 minutos por serie)
        return completedTodaySets * 2
    }
    
    private var weekDays: [(name: String, short: String)] {
        [
            ("Lunes", "L"),
            ("Martes", "M"),
            ("Miércoles", "X"),
            ("Jueves", "J"),
            ("Viernes", "V")
        ]
    }
    
    private var todayIndex: Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return max(0, min(4, weekday - 2)) // Lunes = 0, Viernes = 4
    }
    
    private var weekCompletionStatus: [Bool] {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        // ✅ ARREGLADO: Usar Array(...) para crear un array de enteros
        return (0..<5).map { dayOffset -> Bool in
            // ✅ ARREGLADO: dayOffset ya es Int, no necesita conversión
            let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset) + 1, to: startOfWeek) ?? Date()
            let completed = viewModel.exercisesForDate
            return !completed.isEmpty
        }
    }
}

// MARK: - Fitness Ring
struct FitnessRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Anillo de fondo
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Anillo de progreso
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
        }
    }
}

// MARK: - Fitness Metric
struct FitnessMetric: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    let subtitle: String
    let themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                
                HStack(spacing: 4) {
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Week Day Indicator
struct WeekDayIndicator: View {
    let day: String
    let isCompleted: Bool
    let isToday: Bool
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(circleColor)
                .frame(width: 28, height: 28)
                .overlay(
                    Group {
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else if isToday {
                            Circle()
                                .stroke(AppColors.primary(themeManager: themeManager), lineWidth: 2)
                                .frame(width: 20, height: 20)
                        }
                    }
                )
            
            Text(day)
                .font(.caption2)
                .foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var circleColor: Color {
        if isCompleted {
            return AppColors.primary(themeManager: themeManager)
        } else if isToday {
            return AppColors.cardBackground(isDark: themeManager.isDarkMode)
        } else {
            return AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.3)
        }
    }
    
    private var textColor: Color {
        if isToday {
            return AppColors.primary(themeManager: themeManager)
        } else {
            return AppColors.textSecondary(isDark: themeManager.isDarkMode)
        }
    }
}
