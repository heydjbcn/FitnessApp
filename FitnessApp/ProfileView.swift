import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @State private var showingProfileEdit = false
    
    private func calculateBMI() -> String {
        guard !userManager.userWeight.isEmpty, !userManager.userHeight.isEmpty,
              let weight = Double(userManager.userWeight),
              let height = Double(userManager.userHeight) else {
            return "No disponible"
        }
        
        let heightInMeters = height / 100
        let bmi = weight / (heightInMeters * heightInMeters)
        return String(format: "%.1f", bmi)
    }
    
    private func getWeeklyCompletedWorkouts() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        var completedWorkouts = 0
        for (_, workoutExercises) in workoutViewModel.dailyWorkoutRecords {
            for workoutExercise in workoutExercises {
                if let lastCompleted = workoutExercise.lastSetCompletedAt,
                   lastCompleted >= startOfWeek {
                    completedWorkouts += workoutExercise.completedSets
                }
            }
        }
        return completedWorkouts
    }
    
    private func getWeeklyWorkoutTime() -> String {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        var totalMinutes = 0
        for (_, workoutExercises) in workoutViewModel.dailyWorkoutRecords {
            for workoutExercise in workoutExercises {
                if let lastCompleted = workoutExercise.lastSetCompletedAt,
                   lastCompleted >= startOfWeek {
                    // Estimamos 2 minutos por set completado
                    totalMinutes += workoutExercise.completedSets * 2
                }
            }
        }
        
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func getWeeklyProgress() -> Double {
        let completedWorkouts = getWeeklyCompletedWorkouts()
        // Objetivo semanal de 15 entrenamientos (3 ejercicios x 5 días)
        let weeklyGoal = 15
        return min(Double(completedWorkouts) / Double(weeklyGoal), 1.0)
    }
    
    private func getWeeklyTimeProgress() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        var totalMinutes = 0
        for (_, workoutExercises) in workoutViewModel.dailyWorkoutRecords {
            for workoutExercise in workoutExercises {
                if let lastCompleted = workoutExercise.lastSetCompletedAt,
                   lastCompleted >= startOfWeek {
                    totalMinutes += workoutExercise.completedSets * 2
                }
            }
        }
        
        // Objetivo semanal de 300 minutos (5 horas)
        let weeklyGoalMinutes = 300
        return min(Double(totalMinutes) / Double(weeklyGoalMinutes), 1.0)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        // Header del perfil horizontal
                        HStack(spacing: 16) {
                            Spacer() // Empuja el contenido al centro
                            
                            // Foto de perfil a la izquierda
                            if let imageData = userManager.profileImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppColors.primary(themeManager: themeManager), lineWidth: 3))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                            }
                            
                            // Nombre y botón a la derecha
                            VStack(alignment: .leading, spacing: 12) {
                                Text(userManager.currentUserName.isEmpty ? "Usuario" : userManager.currentUserName)
                                    .font(AppFonts.title)
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                
                                // Botón editar perfil
                                Button(action: {
                                    showingProfileEdit = true
                                }) {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Editar perfil")
                                    }
                                    .font(AppFonts.subtitle)
                                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                    .cornerRadius(16)
                                }
                            }
                            
                            Spacer() // Empuja el contenido al centro
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                        
                        // Estadísticas del perfil
                        VStack(spacing: 12) {
                            Text("Información Personal")
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                // Edad
                                ProfileInfoCard(
                                    icon: "calendar",
                                    title: "Edad",
                                    value: userManager.userAge.isEmpty ? "No especificado" : "\(userManager.userAge) años"
                                )
                                .environmentObject(themeManager)
                                
                                // Altura
                                ProfileInfoCard(
                                    icon: "ruler",
                                    title: "Altura",
                                    value: userManager.userHeight.isEmpty ? "No especificado" : "\(userManager.userHeight) cm"
                                )
                                .environmentObject(themeManager)
                                
                                // Peso
                                ProfileInfoCard(
                                    icon: "scalemass",
                                    title: "Peso",
                                    value: userManager.userWeight.isEmpty ? "No especificado" : "\(userManager.userWeight) kg"
                                )
                                .environmentObject(themeManager)
                                
                                // IMC
                                ProfileInfoCard(
                                    icon: "heart.text.square",
                                    title: "IMC",
                                    value: calculateBMI()
                                )
                                .environmentObject(themeManager)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Progreso y estadísticas
                        VStack(spacing: 12) {
                            Text("Progreso")
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 8) {
                                ProfileProgressCard(
                                    title: "Entrenamientos completados",
                                    value: "\(getWeeklyCompletedWorkouts())",
                                    subtitle: "Esta semana",
                                    progress: getWeeklyProgress(),
                                    themeManager: themeManager
                                )
                                
                                ProfileProgressCard(
                                    title: "Tiempo total de ejercicio",
                                    value: getWeeklyWorkoutTime(),
                                    subtitle: "Esta semana",
                                    progress: getWeeklyTimeProgress(),
                                    themeManager: themeManager
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingProfileEdit) {
                ProfileEditView()
                    .environmentObject(userManager)
                    .environmentObject(themeManager)
            }
        }
    }
}

struct ProfileInfoCard: View {
    let icon: String
    let title: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(AppColors.primary(themeManager: themeManager))
                .frame(height: 32)
            
            Text(title)
                .font(AppFonts.label)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                .lineLimit(1)

            Text(value)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ProfileProgressCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))

                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }

                Spacer()

                Text(value)
                    .font(AppFonts.metric)
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary(themeManager: themeManager)))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserManager())
        .environmentObject(ThemeManager())
}
