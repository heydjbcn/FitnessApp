//
//  DashboardComponents.swift
//  FitnessApp
//
//  Complete dashboard components for the fitness app
//

import SwiftUI

// MARK: - Dashboard Header View (renamed to avoid conflict)
struct DashboardHeaderView: View {
    @Binding var mainSelectedTab: Int
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var showingNotifications = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(userManager.getGreeting())
                    .font(AppFonts.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text("¡Es hora de entrenar!")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.buttonTapped()
                showingNotifications = true
            }) {
                ZStack {
                    Circle()
                        .fill(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                    
                    // Badge para notificaciones no leídas
                    if NotificationStore.shared.unreadCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Text("\(NotificationStore.shared.unreadCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 12, y: -12)
                    }
                }
            }
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
                .environmentObject(themeManager)
        }
    }
}

// MARK: - Weekly Progress View
struct WeeklyProgressView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Progreso Semanal")
                    .font(AppFonts.subtitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Spacer()
                
                Text("\(Int(calculateWeeklyProgress() * 100))%")
                    .font(AppFonts.subtitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
            }
            
            // Barra de progreso
            ProgressView(value: calculateWeeklyProgress())
                .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary(themeManager: themeManager)))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Estadísticas rápidas
            HStack(spacing: 20) {
                WeeklyStatItem(
                    icon: "calendar.badge.checkmark",
                    value: "\(calculateWeeklyCompletedDays())",
                    label: "Días",
                    themeManager: themeManager
                )
                
                WeeklyStatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(calculateWeeklyCompletedSets())",
                    label: "Series",
                    themeManager: themeManager
                )
                
                WeeklyStatItem(
                    icon: "clock.fill",
                    value: "\(calculateWeeklyTotalTime() / 60)",
                    label: "Min",
                    themeManager: themeManager
                )
            }
        }
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0.3 : 0.06), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Functions
    private func calculateWeeklyProgress() -> Double {
        let allDays = WorkoutDay.allCases
        let completedDays = allDays.filter { day in
            guard let records = viewModel.dailyWorkoutRecords[day] else { return false }
            return !records.isEmpty && records.contains { $0.isCompleted }
        }
        return allDays.isEmpty ? 0 : Double(completedDays.count) / Double(allDays.count)
    }
    
    private func calculateWeeklyCompletedDays() -> Int {
        return WorkoutDay.allCases.filter { day in
            guard let records = viewModel.dailyWorkoutRecords[day] else { return false }
            return !records.isEmpty && records.contains { $0.isCompleted }
        }.count
    }
    
    private func calculateWeeklyCompletedSets() -> Int {
        return WorkoutDay.allCases.reduce(0) { total, day in
            let dayRecords = viewModel.dailyWorkoutRecords[day] ?? []
            let completedSets = dayRecords.reduce(0) { $0 + $1.completedSets }
            return total + completedSets
        }
    }
    
    private func calculateWeeklyTotalTime() -> Int {
        // Estimamos 3 minutos por serie completada
        return calculateWeeklyCompletedSets() * 3
    }
}

// MARK: - Weekly Stat Item
struct WeeklyStatItem: View {
    let icon: String
    let value: String
    let label: String
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primary(themeManager: themeManager))
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stats Cards View
struct StatsCardsView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    let onNavigateToBestDay: (WorkoutDay) -> Void
    let onNavigateToExercises: () -> Void
    
    init(onNavigateToBestDay: @escaping (WorkoutDay) -> Void, onNavigateToExercises: @escaping () -> Void) {
        self.onNavigateToBestDay = onNavigateToBestDay
        self.onNavigateToExercises = onNavigateToExercises
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                icon: "flame.fill",
                iconColor: AppColors.danger,
                title: "Racha",
                value: "\(calculateConsecutiveWorkoutDays())",
                subtitle: "días seguidos",
                onTap: nil
            )
            
            StatCard(
                icon: "trophy.fill",
                iconColor: AppColors.primary(themeManager: themeManager),
                title: "Mejor día",
                value: bestDayName(),
                subtitle: "\(Int(bestDayProgress() * 100))% completado",
                onTap: {
                    if let bestDay = calculateBestWorkoutDay() {
                        onNavigateToBestDay(bestDay)
                    }
                }
            )
            
            StatCard(
                icon: "list.bullet",
                iconColor: AppColors.accentBlue,
                title: "Ejercicios",
                value: "\(calculateTotalUniqueExercises())",
                subtitle: "únicos",
                onTap: onNavigateToExercises
            )
            
            StatCard(
                icon: "clock.fill",
                iconColor: AppColors.success,
                title: "Tiempo",
                value: "\(estimatedWeeklyTime())",
                subtitle: "min semanales",
                onTap: nil
            )
        }
    }
    
    // MARK: - Helper Functions
    private func calculateConsecutiveWorkoutDays() -> Int {
        let allDays = WorkoutDay.allCases
        var consecutiveCount = 0
        var currentStreak = 0
        
        for day in allDays {
            guard let records = viewModel.dailyWorkoutRecords[day] else {
                currentStreak = 0
                continue
            }
            
            if !records.isEmpty && records.contains(where: { $0.isCompleted }) {
                currentStreak += 1
                consecutiveCount = max(consecutiveCount, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return consecutiveCount
    }
    
    private func calculateBestWorkoutDay() -> WorkoutDay? {
        var bestDay: WorkoutDay?
        var highestProgress = 0.0
        
        for day in WorkoutDay.allCases {
            let progress = progressForDay(day)
            if progress > highestProgress {
                highestProgress = progress
                bestDay = day
            }
        }
        
        return bestDay
    }
    
    private func calculateTotalUniqueExercises() -> Int {
        var uniqueExerciseIds = Set<UUID>()
        
        for day in WorkoutDay.allCases {
            if let records = viewModel.dailyWorkoutRecords[day] {
                for record in records {
                    uniqueExerciseIds.insert(record.exerciseId)
                }
            }
        }
        
        return uniqueExerciseIds.count
    }
    
    private func bestDayName() -> String {
        guard let bestDay = calculateBestWorkoutDay() else { return "---" }
        switch bestDay {
        case .monday: return "Lun"
        case .tuesday: return "Mar"
        case .wednesday: return "Mié"
        case .thursday: return "Jue"
        case .friday: return "Vie"
        }
    }
    
    private func bestDayProgress() -> Double {
        guard let bestDay = calculateBestWorkoutDay() else { return 0 }
        return progressForDay(bestDay)
    }
    
    private func progressForDay(_ day: WorkoutDay) -> Double {
        guard let workoutRecords = viewModel.dailyWorkoutRecords[day] else { return 0 }
        if workoutRecords.isEmpty { return 0 }
        
        let completedSets = workoutRecords.reduce(0) { $0 + $1.completedSets }
        let totalSets = workoutRecords.compactMap { record in
            viewModel.getExercise(by: record.exerciseId)?.totalSets
        }.reduce(0, +)
        
        return totalSets > 0 ? Double(completedSets) / Double(totalSets) : 0
    }
    
    private func estimatedWeeklyTime() -> Int {
        let totalSets = WorkoutDay.allCases.reduce(0) { daySum, day in
            let dayRecords = viewModel.dailyWorkoutRecords[day] ?? []
            let daySets = dayRecords.compactMap { record in
                viewModel.getExercise(by: record.exerciseId)?.totalSets
            }.reduce(0, +)
            return daySum + daySets
        }
        return totalSets * 3 // 3 minutos por serie estimado
    }
}

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    let onTap: (() -> Void)?
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 20))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    
                    Text(value)
                        .font(.title2.bold())
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .frame(height: 120)
            .padding()
            .cardStyle(isDarkMode: themeManager.isDarkMode)
        }
        .disabled(onTap == nil)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Nuevos Componentes Modernos

// Header moderno con scroll
struct ModernHeaderView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(userManager.getGreeting())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("¡Vamos por un gran entrenamiento!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

// Progreso semanal moderno
struct ModernWeeklyProgressView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Progreso Semanal")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("75%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.accentRed)
            }
            
            // Barra de progreso moderna
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.backgroundSecondary)
                    .frame(height: 12)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.primaryGradient)
                    .frame(width: UIScreen.main.bounds.width * 0.75, height: 12)
            }
            
            // Estadísticas de la semana
            HStack(spacing: 20) {
                WeeklyStatBubble(icon: "calendar.badge.checkmark", value: "5", label: "Días")
                WeeklyStatBubble(icon: "dumbbell.fill", value: "24", label: "Ejercicios")
                WeeklyStatBubble(icon: "clock.fill", value: "3.2h", label: "Tiempo")
            }
        }
        .padding(20)
        .background(AppColors.backgroundCard)
        .cornerRadius(16)
    }
}

// Motivación moderna
struct ModernMotivationView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Motivación Diaria")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(userManager.getMotivationalQuote())
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .italic()
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppColors.backgroundCard)
        .cornerRadius(16)
    }
}

// Botón principal moderno
struct ModernStartWorkoutButton: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTapped()
            selectedTab = 1
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text("Empecemos con tu rutina")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(AppColors.primaryGradient)
            .cornerRadius(16)
            .shadow(color: AppColors.accentRed.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Grid de estadísticas moderno
struct ModernStatsGrid: View {
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ModernStatCard(
                title: "Racha Actual",
                value: "7",
                subtitle: "días",
                icon: "flame.fill",
                color: AppColors.streakCardColor
            )
            
            ModernStatCard(
                title: "Mejor Día",
                value: "Lunes",
                subtitle: "esta semana",
                icon: "star.fill",
                color: AppColors.bestDayCardColor
            )
            
            ModernStatCard(
                title: "Ejercicios",
                value: "24",
                subtitle: "completados",
                icon: "dumbbell.fill",
                color: AppColors.exercisesCardColor
            )
            
            ModernStatCard(
                title: "Tiempo Total",
                value: "3.2h",
                subtitle: "esta semana",
                icon: "clock.fill",
                color: AppColors.timeCardColor
            )
        }
    }
}

// Tarjeta de estadística moderna
struct ModernStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(16)
        .background(AppColors.backgroundCard)
        .cornerRadius(16)
        .frame(height: 120)
    }
}

// Récords personales modernos
struct ModernPersonalRecordsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Récords Personales")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 12) {
                ModernRecordRow(exercise: "Sentadillas", weight: "85kg", date: "Hace 3 días")
                ModernRecordRow(exercise: "Press Banca", weight: "70kg", date: "Hace 1 semana")
                ModernRecordRow(exercise: "Peso Muerto", weight: "100kg", date: "Hace 2 semanas")
            }
        }
        .padding(20)
        .background(AppColors.backgroundCard)
        .cornerRadius(16)
    }
}

// Fila de récord personal
struct ModernRecordRow: View {
    let exercise: String
    let weight: String
    let date: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(date)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            Text(weight)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.accentRed)
        }
        .padding(.vertical, 8)
    }
}

// Programación semanal moderna
struct ModernWeeklyScheduleView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Programación Semanal")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(0..<7) { dayIndex in
                    ModernDayRow(
                        day: getDayName(for: dayIndex),
                        exercises: getExercisesForDay(dayIndex),
                        isToday: dayIndex == getCurrentDayIndex()
                    )
                }
            }
        }
        .padding(20)
        .background(AppColors.backgroundCard)
        .cornerRadius(16)
    }
    
    private func getDayName(for index: Int) -> String {
        let days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        return days[index]
    }
    
    private func getExercisesForDay(_ day: Int) -> [String] {
        switch day {
        case 0: return ["Sentadillas", "Press Banca", "Dominadas"]
        case 1: return ["Peso Muerto", "Press Militar", "Remo"]
        case 2: return ["Descanso"]
        case 3: return ["Sentadillas", "Press Inclinado", "Flexiones"]
        case 4: return ["Peso Muerto", "Pull-ups", "Dips"]
        case 5: return ["Cardio", "Core"]
        case 6: return ["Descanso"]
        default: return []
        }
    }
    
    private func getCurrentDayIndex() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        return (weekday == 1) ? 6 : weekday - 2 // Convertir a índice 0-6 donde 0 = Lunes
    }
}

// Fila de día de la semana
struct ModernDayRow: View {
    let day: String
    let exercises: [String]
    let isToday: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(day)
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(isToday ? AppColors.accentRed : AppColors.textPrimary)
                
                Text(exercises.joined(separator: " • "))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isToday {
                Circle()
                    .fill(AppColors.accentRed)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isToday ? AppColors.accentRed.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

// MARK: - Default Routine Info Card
struct DefaultRoutineInfoCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: WorkoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rutina por Defecto")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Text("Plan de entrenamiento de 3 días")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                Spacer()
                
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
            }
            
            // Información de los días de entrenamiento
            VStack(spacing: 12) {
                DefaultRoutineDayRow(
                    day: "Lunes",
                    focus: "Piernas & Isquios",
                    exercises: 5,
                    isCompleted: hasCompletedDay(.monday),
                    themeManager: themeManager
                )
                
                DefaultRoutineDayRow(
                    day: "Miércoles",
                    focus: "Espalda & Hombros",
                    exercises: 6,
                    isCompleted: hasCompletedDay(.wednesday),
                    themeManager: themeManager
                )
                
                DefaultRoutineDayRow(
                    day: "Viernes",
                    focus: "Piernas Variadas",
                    exercises: 4,
                    isCompleted: hasCompletedDay(.friday),
                    themeManager: themeManager
                )
            }
            
            // Información adicional
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("15 ejercicios totales")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    
                    Text("4 series × 15 repeticiones")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                Spacer()
                
                Text("~45 min/día")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
            }
        }
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0.3 : 0.06), radius: 8, x: 0, y: 4)
    }
    
    private func hasCompletedDay(_ day: WorkoutDay) -> Bool {
        guard let records = viewModel.dailyWorkoutRecords[day] else { return false }
        return !records.isEmpty && records.contains { $0.isCompleted }
    }
}

// MARK: - Default Routine Day Row
struct DefaultRoutineDayRow: View {
    let day: String
    let focus: String
    let exercises: Int
    let isCompleted: Bool
    let themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Indicador de estado
            Circle()
                .fill(isCompleted ? AppColors.success : AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.3))
                .frame(width: 8, height: 8)
            
            // Información del día
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(day)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Text("• \(exercises) ejercicios")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                Text(focus)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            
            Spacer()
            
            // Icono de completado
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.success)
            }
        }
        .padding(.vertical, 4)
    }
}

// Burbuja de estadística semanal
struct WeeklyStatBubble: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.accentRed)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
