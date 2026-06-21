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
        let _ = print("🔥🔥🔥 EXERCISECARDVIEW SE ESTÁ EJECUTANDO PARA: \(exercise.name)")
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill").foregroundColor(AppColors.primary(themeManager: themeManager))
                Text(exercise.name.uppercased()).font(AppFonts.subtitle).foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                Spacer()
                Button { showInfo = true } label: { Image(systemName: "info.circle.fill").foregroundColor(AppColors.accentCyan) }
                Button {
                    withAnimation { 
                        viewModel.removeExercise(recordId: workoutRecord.id, from: day)
                    }
                } label: { Image(systemName: "trash.circle.fill").foregroundColor(AppColors.danger) }
            }

            HStack(spacing: 24) {
                let _ = print("🔥 EJERCICIO: \(exercise.name) - SEGUNDOS: \(exercise.segundos) - REPS: \(exercise.repetitions)")
                
                // MOSTRAR SEGUNDOS si > 0
                if exercise.segundos > 0 {
                    let _ = print("🔥 MOSTRANDO SEGUNDOS: \(exercise.segundos)")
                    infoItem(icon: "timer", text: "\(exercise.segundos)s")
                }
                
                // MOSTRAR REPETICIONES solo si > 0
                if exercise.repetitions > 0 {
                    let _ = print("🔥 MOSTRANDO REPETICIONES: \(exercise.repetitions)")
                    infoItem(icon: "repeat", text: "\(exercise.repetitions) reps")
                }
                
                // SIEMPRE mostrar un texto de debug
                infoItem(icon: "questionmark", text: "DEBUG")
                
                // Mostrar peso solo si es mayor a 0
                if exercise.weight > 0 {
                    infoItem(icon: "scalemass", text: String(format: "%.1f kg", exercise.weight))
                }
                
                infoItem(icon: "number", text: "\(workoutRecord.completedSets)/\(exercise.totalSets) series", color: workoutRecord.completedSets >= exercise.totalSets ? AppColors.success : AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            
            // Segunda fila con información adicional si está disponible
            if exercise.rir > 0 {
                HStack(spacing: 24) {
                    if exercise.rir > 0 {
                        infoItem(icon: "gauge", text: "RIR: \(exercise.rir)")
                    }
                    Spacer() // Para alinear a la izquierda
                }
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
                                .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                        } else {
                            Text("\(idx + 1)")
                                .font(AppFonts.label)
                                .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
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
            Text(text).font(AppFonts.caption).foregroundColor(finalColor)
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
                        
                        // Detalles del ejercicio
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Detalles del Ejercicio")
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "repeat")
                                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                                    Text("Repeticiones:")
                                    Spacer()
                                    Text("\(exercise.repetitions)")
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Image(systemName: "scalemass")
                                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                                    Text("Peso:")
                                    Spacer()
                                    Text(String(format: "%.1f kg", exercise.weight))
                                        .fontWeight(.semibold)
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
                                
                                if exercise.rir > 0 {
                                    HStack {
                                        Image(systemName: "gauge.high")
                                            .foregroundColor(AppColors.primary(themeManager: themeManager))
                                        Text("RIR (Reps en Reserva):")
                                        Spacer()
                                        Text("\(exercise.rir)")
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
                    Button { dismiss() } label: { Image(systemName: "xmark").font(.title3.weight(.bold)) }
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
            }
        }
    }
}
