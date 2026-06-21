//
//  FirebaseStatusView.swift
//  FitnessApp
//
//  Vista para mostrar el estado de Firebase y los ejercicios
//

import SwiftUI

struct FirebaseStatusView: View {
    @ObservedObject var firebaseService: FirebaseExerciseService
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundColor(.orange)
                Text("Estado de Firebase")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Spacer()
                
                if firebaseService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Estadísticas de ejercicios
            let stats = workoutViewModel.getExerciseStats()
            
            VStack(alignment: .leading, spacing: 8) {
                ExerciseStatRow(
                    icon: "cloud.fill",
                    label: "Ejercicios de Firebase",
                    value: "\(stats.firebase)",
                    color: .orange
                )
                
                ExerciseStatRow(
                    icon: "person.fill",
                    label: "Ejercicios personalizados",
                    value: "\(stats.local)",
                    color: .blue
                )
                
                ExerciseStatRow(
                    icon: "dumbbell.fill",
                    label: "Total disponibles",
                    value: "\(stats.total)",
                    color: .green
                )
            }
            
            // Error message si existe
            if let error = firebaseService.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Botón de actualización
            Button(action: {
                workoutViewModel.refreshExercisesFromFirebase()
                HapticManager.shared.buttonTapped()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Actualizar desde Firebase")
                }
                .font(.caption)
                .foregroundColor(AppColors.primary(themeManager: themeManager))
            }
            .disabled(firebaseService.isLoading)
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
}

struct ExerciseStatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    FirebaseStatusView(firebaseService: FirebaseExerciseService.shared)
        .environmentObject(WorkoutViewModel())
        .environmentObject(ThemeManager())
}
