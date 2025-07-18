//
//  ExerciseCardView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import SwiftUI
import UIKit

struct ExerciseCardView: View {
    let exercise: Exercise
    let day: WorkoutDay
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill").foregroundColor(AppColors.primary)
                Text(exercise.name.uppercased()).font(.headline.weight(.bold)).foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                Spacer()
                Button { showInfo = true } label: { Image(systemName: "info.circle.fill").foregroundColor(AppColors.accentCyan) }
                Button {
                    if let i = viewModel.exercises[day]?.firstIndex(where: { $0.id == exercise.id }) {
                        withAnimation { viewModel.removeExercise(from: day, at: i) }
                    }
                } label: { Image(systemName: "trash.circle.fill").foregroundColor(AppColors.danger) }
            }

            HStack(spacing: 24) {
                infoItem(icon: "repeat", text: "\(exercise.repetitions) reps")
                infoItem(icon: "scalemass.fill", text: String(format: "%.1f kg", exercise.weight))
                infoItem(icon: "number", text: "\(exercise.completedSets)/\(exercise.totalSets) series", color: exercise.isCompleted ? AppColors.success : AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }

            HStack(spacing: 0) {
                ForEach(0..<exercise.totalSets, id: \.self) { idx in
                    ZStack {
                        Circle()
                            .fill(idx < exercise.completedSets ? AppColors.primary : AppColors.primary)
                            .frame(width: 28, height: 28)
                        
                        if idx < exercise.completedSets {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                        } else {
                            Text("\(idx + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.spring()) {
                            if idx < exercise.completedSets && idx == exercise.completedSets - 1 {
                                viewModel.undoLastSet(for: day, exerciseId: exercise.id)
                            } else if idx == exercise.completedSets {
                                viewModel.completeSet(for: day, exerciseId: exercise.id)
                            }
                        }
                    }
                    if idx < exercise.totalSets - 1 { Spacer(minLength: 4) }
                }
            }
        }
        .padding().background(AppColors.cardBackground(isDark: themeManager.isDarkMode)).cornerRadius(12).opacity(exercise.isCompleted ? 0.7 : 1.0)
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
