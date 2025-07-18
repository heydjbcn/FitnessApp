//
//  ExerciseCardView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import SwiftUI
import UIKit

struct ExerciseCardView: View {
    let workoutRecord: WorkoutExercise
    let exercise: Exercise
    let day: WorkoutDay
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill").foregroundColor(AppColors.primary(themeManager: themeManager))
                Text(exercise.name.uppercased()).font(.headline.weight(.bold)).foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                Spacer()
                Button { showInfo = true } label: { Image(systemName: "info.circle.fill").foregroundColor(AppColors.accentCyan) }
                Button {
                    withAnimation { 
                        viewModel.removeExercise(recordId: workoutRecord.id, from: day)
                    }
                } label: { Image(systemName: "trash.circle.fill").foregroundColor(AppColors.danger) }
            }

            HStack(spacing: 24) {
                infoItem(icon: "repeat", text: "\(exercise.repetitions) reps")
                infoItem(icon: "scalemass.fill", text: String(format: "%.1f kg", exercise.weight))
                infoItem(icon: "number", text: "\(workoutRecord.completedSets)/\(exercise.totalSets) series", color: workoutRecord.completedSets >= exercise.totalSets ? AppColors.success : AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }

            HStack(spacing: 0) {
                ForEach(0..<exercise.totalSets, id: \.self) { idx in
                    ZStack {
                        Circle()
                            .fill(idx < workoutRecord.completedSets ? AppColors.primary(themeManager: themeManager) : AppColors.primary(themeManager: themeManager).opacity(0.3))
                            .frame(width: 28, height: 28)
                        
                        if idx < workoutRecord.completedSets {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(idx + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.spring()) {
                            if idx < workoutRecord.completedSets && idx == workoutRecord.completedSets - 1 {
                                viewModel.undoLastSet(for: workoutRecord.id, in: day)
                            } else if idx == workoutRecord.completedSets {
                                viewModel.completeSet(for: workoutRecord.id, in: day)
                            }
                        }
                    }
                    if idx < exercise.totalSets - 1 { Spacer(minLength: 4) }
                }
            }
        }
        .padding().background(AppColors.cardBackground(isDark: themeManager.isDarkMode)).cornerRadius(12).opacity(workoutRecord.completedSets >= exercise.totalSets ? 0.7 : 1.0)
        .sheet(isPresented: $showInfo) {
            ExerciseInfoSheet(exercise: exercise)
        }
    }

    private func infoItem(icon: String, text: String, color: Color? = nil) -> some View {
        let finalColor = color ?? AppColors.textPrimary(isDark: themeManager.isDarkMode)
        
        return HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(AppColors.accentCyan)
            Text(text).font(.caption.weight(.semibold)).foregroundColor(finalColor)
        }
    }
}

struct ExerciseInfoSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if let imageData = exercise.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage).resizable().scaledToFit().cornerRadius(12).padding(.horizontal)
                        }
                        
                        Text(exercise.info.isEmpty ? "No hay descripción para este ejercicio." : exercise.info)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark").font(.title3.weight(.bold)) }
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}
