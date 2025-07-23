import SwiftUI

struct ExerciseHistoryDetailView: View {
    let exercise: Exercise
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header del ejercicio con mejor diseño
                VStack(spacing: 20) {
                    // Icono del ejercicio con gradiente
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppColors.primary(themeManager: themeManager),
                                        AppColors.primary(themeManager: themeManager).opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: AppColors.primary(themeManager: themeManager).opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        if let iconName = exercise.sfSymbolIcon {
                            Image(systemName: iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        } else {
                            Image(systemName: "dumbbell.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Nombre del ejercicio
                    Text(exercise.name.capitalized)
                        .font(AppFonts.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        .multilineTextAlignment(.center)
                    
                    // Estadísticas en cards pequeñas
                    HStack(spacing: 16) {
                        statCard(value: "\(exercise.totalSets)", label: "Series")
                        statCard(value: "\(exercise.repetitions)", label: "Reps")
                        statCard(value: "\(String(format: "%.1f", exercise.weight))", label: "kg")
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Lista de historial
                ScrollView {
                    if exerciseHistory.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.6))
                            
                            VStack(spacing: 8) {
                                Text("Sin historial")
                                    .font(AppFonts.title)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                
                                Text("Aún no has realizado este ejercicio")
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                        .padding(.horizontal, 40)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(exerciseHistory.indices, id: \.self) { index in
                                exerciseHistoryCard(for: exerciseHistory[index])
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }
                .background(AppColors.background(isDark: themeManager.isDarkMode))
            }
            .background(AppColors.background(isDark: themeManager.isDarkMode))
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    }
                }
            }
        }
    }
    
    // Función para crear las pequeñas cards de estadísticas
    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(AppFonts.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primary(themeManager: themeManager))
            
            Text(label)
                .font(AppFonts.caption)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
        }
        .frame(minWidth: 70)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // Historial de ejercicio filtrado por el ejercicio específico
    private var exerciseHistory: [(date: Date, workout: WorkoutExercise)] {
        var history: [(date: Date, workout: WorkoutExercise)] = []
        
        for (date, workoutsByDay) in viewModel.workoutHistory {
            for (_, workouts) in workoutsByDay {
                for workout in workouts {
                    if workout.exerciseId == exercise.id {
                        history.append((date: date, workout: workout))
                    }
                }
            }
        }
        
        return history.sorted { $0.date > $1.date }
    }
    
    private func exerciseHistoryCard(for historyItem: (date: Date, workout: WorkoutExercise)) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formatDate(historyItem.date))
                    .font(AppFonts.subtitle)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                Spacer()
                
                Text("\(historyItem.workout.completedSets)/\(exercise.totalSets) series")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            
            // Estadísticas del workout
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Series completadas")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    Text("\(historyItem.workout.completedSets)")
                        .font(AppFonts.subtitle)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Peso usado")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    Text("\(String(format: "%.1f", exercise.weight)) kg")
                        .font(AppFonts.subtitle)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
                
                Spacer()
            }
            
            // Barra de progreso
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progreso")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    Spacer()
                    Text("\(Int((Double(historyItem.workout.completedSets) / Double(exercise.totalSets)) * 100))%")
                        .font(AppFonts.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
                
                ProgressView(value: Double(historyItem.workout.completedSets), total: Double(exercise.totalSets))
                    .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary(themeManager: themeManager)))
                    .scaleEffect(x: 1, y: 0.6, anchor: .center)
            }
        }
        .padding(16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: date).capitalized
    }
}

#Preview {
    ExerciseHistoryDetailView(exercise: Exercise(
        name: "Press de banca",
        repetitions: 10,
        weight: 80.0,
        totalSets: 4,
        info: "",
        imageData: nil,
        restDuration: 90,
        sfSymbolIcon: "figure.strengthtraining.traditional",
        iconColor: "blue",
        segundos: 0,
        rir: 0,
        personalRecordWeight: nil
    ))
    .environmentObject(WorkoutViewModel())
    .environmentObject(ThemeManager())
}
