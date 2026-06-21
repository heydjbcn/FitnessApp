//
//  EnhancedExerciseCardView.swift
//  FitnessApp
//
//  Tarjeta mejorada de ejercicios con más información
//

import SwiftUI

struct EnhancedExerciseCardView: View {
    let exercise: Exercise
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showingEditView = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con icono y información principal
            HStack(spacing: 12) {
                // Icono del ejercicio
                ZStack {
                    Circle()
                        .fill(exerciseTypeColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: exercise.sfSymbolIcon ?? "dumbbell.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(exerciseTypeColor)
                }
                
                // Información principal
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        .lineLimit(2)
                    
                    // Grupo muscular
                    HStack(spacing: 8) {
                        Text(muscleGroupDisplay)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(muscleGroupColor.opacity(0.1))
                            )
                            .foregroundColor(muscleGroupColor)
                        
                        Text(exerciseTypeDisplay)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(exerciseTypeColor.opacity(0.1))
                            )
                            .foregroundColor(exerciseTypeColor)
                    }
                }
                
                Spacer()
                
                // Botón de editar
                Button(action: { showingEditView = true }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(AppColors.primary(themeManager: themeManager).opacity(0.1))
                        )
                }
            }
            .padding()
            
            // Divider
            Divider()
                .padding(.horizontal)
            
            // Parámetros del ejercicio
            HStack(spacing: 16) {
                if exercise.totalSets > 0 {
                    parameterView(
                        icon: "number.circle",
                        label: "Series",
                        value: "\(exercise.totalSets)"
                    )
                }
                
                if exercise.repetitions > 0 {
                    parameterView(
                        icon: "repeat.circle",
                        label: "Reps",
                        value: "\(exercise.repetitions)"
                    )
                }
                
                if exercise.weight > 0 {
                    parameterView(
                        icon: "scalemass",
                        label: "Peso",
                        value: "\(String(format: "%.1f", exercise.weight))kg"
                    )
                }
                
                if exercise.segundos > 0 {
                    parameterView(
                        icon: "clock",
                        label: "Tiempo",
                        value: "\(exercise.segundos)s"
                    )
                }
                
                Spacer()
                
                // Origen del ejercicio
                VStack(spacing: 2) {
                    Image(systemName: exercise.isFromFirebase ? "cloud.fill" : "person.fill")
                        .font(.caption)
                        .foregroundColor(exercise.isFromFirebase ? .orange : .blue)
                    
                    Text(exercise.isFromFirebase ? "Firebase" : "Personal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingEditView) {
            ExerciseFormView(exercise: exercise)
        }
    }
    
    private func parameterView(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppColors.primary(themeManager: themeManager))
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var muscleGroupDisplay: String {
        if !exercise.targetMuscle.isEmpty {
            return exercise.targetMuscle
        }
        return "General"
    }
    
    private var muscleGroupColor: Color {
        // Inferir color basado en el músculo objetivo
        let muscle = exercise.targetMuscle.lowercased()
        if muscle.contains("pecho") { return .red }
        else if muscle.contains("espalda") { return .green }
        else if muscle.contains("hombro") { return .orange }
        else if muscle.contains("brazo") { return .blue }
        else if muscle.contains("pierna") { return .purple }
        else if muscle.contains("core") { return .yellow }
        else { return .gray }
    }
    
    private var exerciseTypeDisplay: String {
        if exercise.isBodyWeight {
            return "Peso Corporal"
        } else if exercise.category == .cardio {
            return "Cardio"
        } else {
            return "Peso Libre"
        }
    }
    
    private var exerciseTypeColor: Color {
        if exercise.isBodyWeight {
            return .green
        } else if exercise.category == .cardio {
            return .red
        } else {
            return .blue
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        EnhancedExerciseCardView(
            exercise: Exercise(
                name: "Press Banca",
                repetitions: 8,
                weight: 60.0,
                totalSets: 3,
                info: "Ejercicio fundamental para pecho",
                restDuration: 120,
                sfSymbolIcon: "figure.strengthtraining.traditional",
                iconColor: "red"
            )
        )
        
        EnhancedExerciseCardView(
            exercise: Exercise(
                name: "Flexiones",
                repetitions: 15,
                weight: 0.0,
                totalSets: 3,
                info: "Ejercicio de peso corporal",
                restDuration: 60,
                sfSymbolIcon: "figure.strengthtraining.traditional",
                iconColor: "green"
            )
        )
    }
    .padding()
    .environmentObject(ThemeManager())
}
