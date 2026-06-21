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
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(AppColors.accentRed)
                Text(exercise.name.uppercased())
                    .font(.headline.weight(.bold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button { showInfo = true } label: {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppColors.accentBlue)
                }
                Button {
                    withAnimation { 
                        viewModel.removeExercise(recordId: workoutRecord.id, from: day)
                    }
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(AppColors.danger)
                }
            }

            HStack(spacing: 24) {
                // MOSTRAR SEGUNDOS si > 0
                if exercise.segundos > 0 {
                    infoItem(icon: "timer", text: "\(exercise.segundos)s")
                }
                
                // MOSTRAR REPETICIONES solo si > 0
                if exercise.repetitions > 0 {
                    infoItem(icon: "repeat", text: "\(exercise.repetitions) reps")
                }
                
                // Mostrar peso solo si es mayor a 0
                if exercise.weight > 0 {
                    infoItem(icon: "scalemass", text: String(format: "%.1f kg", exercise.weight))
                }
                
                infoItem(
                    icon: "number", 
                    text: "\(workoutRecord.completedSets)/\(exercise.totalSets) series",
                    color: workoutRecord.completedSets >= exercise.totalSets ? AppColors.success : AppColors.textSecondary(isDark: themeManager.isDarkMode)
                )
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
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
        .opacity(workoutRecord.completedSets >= exercise.totalSets ? 0.7 : 1.0)
        .sheet(isPresented: $showInfo) {
            ExerciseInfoSheet(exercise: exercise)
        }
    }

    private func infoItem(icon: String, text: String, color: Color? = nil) -> some View {
        let finalColor = color ?? AppColors.textPrimary
        
        return HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.accentBlue)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundColor(finalColor)
        }
    }
}

struct ExerciseInfoSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: WorkoutViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if let imageData = exercise.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        
                        Text(exercise.info.isEmpty ? "No hay descripción para este ejercicio." : exercise.info)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            .padding(.horizontal)
                        
                        // Detalles del ejercicio
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Detalles del Ejercicio")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                if exercise.repetitions > 0 {
                                    HStack {
                                        Image(systemName: "repeat")
                                            .foregroundColor(AppColors.primary(themeManager: themeManager))
                                        Text("Repeticiones:")
                                        Spacer()
                                        Text("\(exercise.repetitions)")
                                            .fontWeight(.semibold)
                                    }
                                }
                                
                                if exercise.weight > 0 {
                                    HStack {
                                        Image(systemName: "scalemass")
                                            .foregroundColor(AppColors.primary(themeManager: themeManager))
                                        Text("Peso:")
                                        Spacer()
                                        Text(String(format: "%.1f kg", exercise.weight))
                                            .fontWeight(.semibold)
                                    }
                                }
                                
                                HStack {
                                    Image(systemName: "list.number")
                                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                                    Text("Total de Sets:")
                                    Spacer()
                                    Text("\(exercise.totalSets)")
                                        .fontWeight(.semibold)
                                }
                                
                                if exercise.segundos > 0 {
                                    HStack {
                                        Image(systemName: "timer")
                                            .foregroundColor(AppColors.primary(themeManager: themeManager))
                                        Text("Segundos:")
                                        Spacer()
                                        Text("\(exercise.segundos)s")
                                            .fontWeight(.semibold)
                                    }
                                }
                                
                                HStack {
                                    Image(systemName: "timer.circle")
                                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                                    Text("Descanso:")
                                    Spacer()
                                    Text("\(exercise.restDuration / 60):\(String(format: "%02d", exercise.restDuration % 60))")
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.bold))
                            .foregroundColor(AppColors.accentRed)
                    }
                }
            }
        }
    }
}
