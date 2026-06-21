//
//  WeeklyProgressView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import SwiftUI

// MARK: - Tarjeta grande de progreso semanal (fondo lima)
struct WeeklyProgressView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager

    // Entrenamientos completados (días activos con todas las series hechas)
    private var completedWorkouts: Int {
        viewModel.activeDays.filter { viewModel.progressForDay($0) >= 1.0 }.count
    }

    private var totalWorkouts: Int {
        viewModel.activeDays.count
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("PROGRESO SEMANAL")
                    .font(AppFonts.label)
                    .tracking(1.2)
                    .foregroundColor(AppColors.onPrimary(themeManager: themeManager).opacity(0.8))

                Text("\(Int(viewModel.weeklyProgress() * 100))%")
                    .font(AppFonts.bigMetric)
                    .foregroundColor(AppColors.onPrimary(themeManager: themeManager))

                Text("\(completedWorkouts) de \(totalWorkouts) entrenamientos")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.onPrimary(themeManager: themeManager).opacity(0.85))
            }

            Spacer()

            // Anillo de progreso con icono mancuerna
            ZStack {
                Circle()
                    .stroke(AppColors.onPrimary(themeManager: themeManager).opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: viewModel.weeklyProgress())
                    .stroke(AppColors.onPrimary(themeManager: themeManager), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: viewModel.weeklyProgress())

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.primary(themeManager: themeManager))
        .cornerRadius(20)
    }
}

// MARK: - Sección "Hoy · <día>" con la lista de ejercicios del día y barra segmentada
struct WeeklyExercisesList: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager

    private let today: WorkoutDay = WeeklyCalendarView.getCurrentDay()

    private var todayRecords: [WorkoutExercise] {
        viewModel.dailyWorkoutRecords[today] ?? []
    }

    private var completedSetsToday: Int {
        todayRecords.map { $0.completedSets }.reduce(0, +)
    }

    private var totalSetsToday: Int {
        todayRecords.compactMap { viewModel.getExercise(by: $0.exerciseId)?.totalSets }.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cabecera de sección: "Hoy · Lunes" + badge de series
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(AppColors.primary(themeManager: themeManager))
                        .frame(width: 8, height: 8)
                    Text("Hoy · \(dayName(for: today))")
                        .font(AppFonts.title)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }

                Spacer()

                Text("\(completedSetsToday)/\(totalSetsToday) series")
                    .font(AppFonts.label)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                    .cornerRadius(20)
            }

            if todayRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.5))
                    Text("No hay ejercicios para hoy")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    Text("Agrega ejercicios desde Ejercicios")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .cardStyle(isDarkMode: themeManager.isDarkMode)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(todayRecords) { record in
                        if let exercise = viewModel.getExercise(by: record.exerciseId) {
                            TodayExerciseRow(exercise: exercise, record: record)
                                .environmentObject(themeManager)
                        }
                    }
                }
            }
        }
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

// MARK: - Fila de ejercicio del día con barra de progreso segmentada
struct TodayExerciseRow: View {
    let exercise: Exercise
    let record: WorkoutExercise
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icono lima en cuadrado redondeado
                Image(systemName: exercise.sfSymbolIcon ?? "dumbbell.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.primary(themeManager: themeManager))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(AppFonts.subtitle)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        .lineLimit(1)

                    Text("\(exercise.repetitions) reps · \(formattedWeight) kg")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }

                Spacer()

                // Progreso n/total en lima
                Text("\(record.completedSets)/\(exercise.totalSets)")
                    .font(AppFonts.metric)
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
            }

            // Barra de progreso segmentada (un segmento por serie)
            HStack(spacing: 6) {
                ForEach(0..<max(exercise.totalSets, 1), id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(index < record.completedSets
                              ? AppColors.primary(themeManager: themeManager)
                              : AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.25))
                        .frame(height: 6)
                }
            }
        }
        .padding(16)
        .cardStyle(isDarkMode: themeManager.isDarkMode)
        .onTapGesture { showingInfo = true }
        .alert("Información del ejercicio", isPresented: $showingInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exercise.info.isEmpty ? "Ejercicio: \(exercise.name)\nSeries: \(exercise.totalSets)\nRepeticiones: \(exercise.repetitions)\nPeso: \(formattedWeight) kg" : exercise.info)
        }
    }

    private var formattedWeight: String {
        let w = exercise.weight
        return w == w.rounded() ? String(Int(w)) : String(format: "%.1f", w)
    }
}
