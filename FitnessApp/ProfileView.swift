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

    private func bmiCategory() -> (name: String, color: Color)? {
        guard !userManager.userWeight.isEmpty, !userManager.userHeight.isEmpty,
              let weight = Double(userManager.userWeight),
              let height = Double(userManager.userHeight), height > 0 else { return nil }
        let bmi = weight / pow(height / 100, 2)
        switch bmi {
        case ..<18.5:   return ("Bajo", AppColors.accentBlue)
        case 18.5..<25: return ("Normal", AppColors.success)
        case 25..<30:   return ("Sobrepeso", AppColors.accentOrange)
        default:        return ("Obesidad", AppColors.accentRed)
        }
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
            ZStack {
                AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header del perfil (centrado y aireado)
                        VStack(spacing: 14) {
                            // Avatar
                            Group {
                                if let imageData = userManager.profileImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 96, height: 96)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                                        .frame(width: 96, height: 96)
                                        .background(Circle().fill(AppColors.cardBackground(isDark: themeManager.isDarkMode)))
                                }
                            }
                            .overlay(Circle().stroke(AppColors.primary(themeManager: themeManager), lineWidth: 3))

                            // Nombre
                            Text(userManager.currentUserName.isEmpty ? "Usuario" : userManager.currentUserName)
                                .font(AppFonts.title2)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))

                            // Botón editar perfil (pill centrado)
                            Button(action: {
                                showingProfileEdit = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil")
                                    Text("Editar perfil")
                                }
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.primary(themeManager: themeManager))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule().fill(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                )
                                .overlay(
                                    Capsule().stroke(AppColors.hairline(isDark: themeManager.isDarkMode), lineWidth: 1)
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                        
                        // Estadísticas del perfil
                        VStack(spacing: 12) {
                            Text("Información Personal")
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
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
                                    value: calculateBMI(),
                                    note: bmiCategory()?.name,
                                    accent: bmiCategory()?.color
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

                        // Resumen semanal por grupo muscular
                        WeeklyMuscleSummary()
                            .padding(.horizontal)

                        // Gráfica de evolución del peso corporal
                        BodyWeightChart()
                            .padding(.horizontal)

                        // Exportar datos (CSV)
                        ShareLink(item: workoutViewModel.exportCSV()) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Exportar datos (CSV)")
                            }
                            .font(AppFonts.subtitle)
                            .foregroundColor(AppColors.primary(themeManager: themeManager))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppColors.primary(themeManager: themeManager), lineWidth: 1.5)
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
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
    var note: String? = nil          // p.ej. categoría de IMC
    var accent: Color? = nil         // color del badge de la nota
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 14) {
            // Icono + etiqueta a la izquierda
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    .lineLimit(1)
            }

            Spacer()

            // Valor (+ nota/categoría opcional) a la derecha
            HStack(spacing: 8) {
                if let note = note, let accent = accent {
                    Text(note.uppercased())
                        .font(AppFonts.label)
                        .foregroundColor(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(accent.opacity(0.15)))
                }
                Text(value)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .padding(.horizontal, 16)
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
