//
//  WorkoutDayView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import SwiftUI

struct WorkoutDayView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    let day: WorkoutDay

    private var exercisesForDay: [WorkoutExercise] { viewModel.dailyWorkoutRecords[day] ?? [] }
    private var progress: Double { viewModel.progressForDay(day) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header reutilizable con progreso semanal
                    HeaderView()
                        .environmentObject(themeManager)
                        .environmentObject(userManager)
                        .environmentObject(viewModel)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    
                    // Contenido del día específico
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Tarjeta de progreso del día
                            progressCard
                                .padding(.horizontal)

                            if exercisesForDay.isEmpty {
                                EmptyStateView()
                                    .padding(.top, 40)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(exercisesForDay) { workoutRecord in
                                        if let exercise = viewModel.getExercise(by: workoutRecord.exerciseId) {
                                            ExerciseCardView(workoutRecord: workoutRecord, exercise: exercise, day: day)
                                                .environmentObject(viewModel)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.bottom, viewModel.timerActive ? 60 : 24)
                    }
                    
                    // Timer de descanso (overlay fijo)
                    if viewModel.timerActive {
                        TimerView()
                            .environmentObject(viewModel)
                            .environmentObject(themeManager)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, 100)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }
    
    private var progressCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(AppColors.secondaryGray, lineWidth: 8)
                Circle().trim(from: 0, to: progress).stroke(AppColors.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90)).animation(.easeInOut, value: progress)
                Text("\(Int(progress * 100))%").font(.caption.weight(.bold))
            }
            .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(day.rawValue).font(.title2.weight(.bold)).foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                HStack(spacing: 16) {
                    let doneCount = exercisesForDay.compactMap { record in
                        if let baseExercise = viewModel.getExercise(by: record.exerciseId) {
                            return record.completedSets >= baseExercise.totalSets ? 1 : 0
                        }
                        return 0
                    }.reduce(0, +)
                    Text("\(doneCount) Hechos").font(.subheadline.weight(.medium)).foregroundColor(AppColors.success)
                    Text("\(exercisesForDay.count) Total").font(.subheadline.weight(.medium)).foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
            }
            Spacer()
        }.padding().background(AppColors.cardBackground(isDark: themeManager.isDarkMode)).cornerRadius(16)
    }
}

struct EmptyStateView: View {
    @EnvironmentObject var themeManager: ThemeManager
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell").font(.system(size: 50)).foregroundColor(AppColors.primary.opacity(0.7))
            Text("No hay ejercicios").font(.headline).foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            Text("Añade ejercicios desde el menú de Configuración.").font(.subheadline).foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode)).multilineTextAlignment(.center)
        }.padding()
    }
}
