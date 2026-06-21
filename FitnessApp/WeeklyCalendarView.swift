import SwiftUI

struct WeeklyCalendarView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @State private var selectedDay: WorkoutDay = getCurrentDay()
    var onNavigateToAddExercise: (() -> Void)?
    
    private var daysWithExercises: [WorkoutDay] {
        WorkoutDay.allCases.sorted { d1, d2 in
            WorkoutDay.allCases.firstIndex(of: d1)! < WorkoutDay.allCases.firstIndex(of: d2)!
        }
    }
    
    // Función para obtener el día actual
    static func getCurrentDay() -> WorkoutDay {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // weekday: 1 = domingo, 2 = lunes, 3 = martes, 4 = miércoles, 5 = jueves, 6 = viernes, 7 = sábado
        switch weekday {
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .monday // Por defecto lunes si es fin de semana
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Progreso del día seleccionado
                        DailyProgressContainer(day: selectedDay)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        
                        // Selector de días
                        HStack(spacing: 8) {
                            ForEach(daysWithExercises, id: \.self) { day in
                                DayCard(
                                    day: day,
                                    isSelected: selectedDay == day,
                                    exerciseCount: viewModel.dailyWorkoutRecords[day]?.count ?? 0,
                                    themeManager: themeManager
                                ) {
                                    selectedDay = day
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        
                        // Lista de ejercicios
                        VStack(spacing: 20) {
                            if let workoutRecords = viewModel.dailyWorkoutRecords[selectedDay], !workoutRecords.isEmpty {
                                LazyVStack(spacing: 16) {
                                    ForEach(workoutRecords, id: \.id) { workoutRecord in
                                        if let exercise = viewModel.getExercise(by: workoutRecord.exerciseId) {
                                            CalendarExerciseCard(
                                                exercise: exercise,
                                                workoutRecord: workoutRecord,
                                                onTimerStart: { duration in
                                                    if viewModel.isTimerEnabled {
                                                        viewModel.restTime = TimeInterval(duration)
                                                        viewModel.startRestTimer()
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            } else {
                                // Vista vacía
                                VStack(spacing: 16) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 60))
                                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                    
                                    Text("No hay entrenamientos")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                    
                                    Text("Agrega ejercicios para comenzar tu rutina")
                                        .font(.body)
                                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                        .multilineTextAlignment(.center)
                                    
                                    Button(action: {
                                        onNavigateToAddExercise?()
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Agregar Ejercicio")
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(AppColors.accentRed)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal, 40)
                                .padding(.vertical, 60)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .onAppear {
                viewModel.selectedDay = selectedDay
            }
        }
    }

struct CalendarExerciseCard: View {
    let exercise: Exercise
    let workoutRecord: WorkoutExercise
    let onTimerStart: (Int) -> Void
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingTooltip = false
    @State private var showingExerciseDetail = false
    @State private var showingExerciseEdit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    if !exercise.info.isEmpty {
                        Text(exercise.info)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingExerciseDetail = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(AppColors.accentBlue)
                        .font(.title2)
                }
            }
            
            // Información del ejercicio
            HStack(spacing: 16) {
                if exercise.repetitions > 0 {
                    InfoPill(icon: "repeat", text: "\(exercise.repetitions) reps")
                }
                
                if exercise.weight > 0 {
                    InfoPill(icon: "scalemass", text: String(format: "%.1f kg", exercise.weight))
                }
                
                if exercise.segundos > 0 {
                    InfoPill(icon: "timer", text: "\(exercise.segundos)s")
                }
                
                InfoPill(
                    icon: "number",
                    text: "\(workoutRecord.completedSets)/\(exercise.totalSets)",
                    color: workoutRecord.isCompleted ? AppColors.success : AppColors.textSecondary(isDark: themeManager.isDarkMode)
                )
            }
            
            // Progreso de series
            HStack(spacing: 0) {
                ForEach(0..<exercise.totalSets, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(index < workoutRecord.completedSets ? AppColors.primary(themeManager: themeManager) : AppColors.primary(themeManager: themeManager).opacity(0.3))
                            .frame(width: 32, height: 32)
                        
                        if index < workoutRecord.completedSets {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .onTapGesture {
                        if index < workoutRecord.completedSets && index == workoutRecord.completedSets - 1 {
                            // Deshacer última serie
                            viewModel.undoLastSet(for: workoutRecord.id, in: viewModel.selectedDay)
                        } else if index == workoutRecord.completedSets {
                            // Completar siguiente serie
                            viewModel.completeSet(for: workoutRecord.id, in: viewModel.selectedDay)
                            
                            // Iniciar timer si está habilitado
                            if viewModel.isTimerEnabled && exercise.restDuration > 0 {
                                onTimerStart(exercise.restDuration)
                            }
                        }
                    }
                    
                    if index < exercise.totalSets - 1 {
                        Spacer(minLength: 4)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
        .opacity(workoutRecord.isCompleted ? 0.7 : 1.0)
        .sheet(isPresented: $showingExerciseDetail) {
            ExerciseDetailView(exercise: exercise)
        }
    }
}

struct InfoPill: View {
    let icon: String
    let text: String
    var color: Color = AppColors.accentBlue
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DailyProgressContainer: View {
    let day: WorkoutDay
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Progreso de \(day.displayName)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Spacer()
                
                Text("\(completedExercises)/\(totalExercises)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary(themeManager: themeManager)))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
    
    private var workoutRecords: [WorkoutExercise] {
        viewModel.dailyWorkoutRecords[day] ?? []
    }
    
    private var completedExercises: Int {
        workoutRecords.filter { $0.isCompleted }.count
    }
    
    private var totalExercises: Int {
        workoutRecords.count
    }
    
    private var progressValue: Double {
        guard totalExercises > 0 else { return 0.0 }
        return Double(completedExercises) / Double(totalExercises)
    }
}

struct DayCard: View {
    let day: WorkoutDay
    let isSelected: Bool
    let exerciseCount: Int
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(day.shortName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : AppColors.textSecondary(isDark: themeManager.isDarkMode))
                
                Text("\(exerciseCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Circle()
                    .fill(exerciseCount > 0 ? AppColors.success : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? AppColors.primary(themeManager: themeManager) : AppColors.cardBackground(isDark: themeManager.isDarkMode)
            )
            .cornerRadius(12)
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let imageData = exercise.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    }
                    
                    Text(exercise.info.isEmpty ? "No hay descripción disponible." : exercise.info)
                        .font(.body)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detalles")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        if exercise.repetitions > 0 {
                            DetailRow(icon: "repeat", title: "Repeticiones", value: "\(exercise.repetitions)")
                        }
                        
                        if exercise.weight > 0 {
                            DetailRow(icon: "scalemass", title: "Peso", value: String(format: "%.1f kg", exercise.weight))
                        }
                        
                        if exercise.segundos > 0 {
                            DetailRow(icon: "timer", title: "Duración", value: "\(exercise.segundos)s")
                        }
                        
                        DetailRow(icon: "list.number", title: "Series", value: "\(exercise.totalSets)")
                        DetailRow(icon: "timer.circle", title: "Descanso", value: "\(exercise.restDuration / 60):\(String(format: "%02d", exercise.restDuration % 60))")
                    }
                }
                .padding()
            }
            .background(AppColors.backgroundPrimary)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary(themeManager: themeManager))
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
        }
    }
}

#Preview {
    WeeklyCalendarView()
        .environmentObject(WorkoutViewModel())
        .environmentObject(ThemeManager())
        .environmentObject(UserManager())
}

// MARK: - Botón de Serie Moderno
struct ModernSetButton: View {
    let setNumber: Int
    let isCompleted: Bool
    let isCurrent: Bool
    let canUndo: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 2)
                    )
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(setNumber)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(textColor)
                }
            }
        }
        .disabled(!isCurrent && !canUndo)
        .scaleEffect(isCurrent ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCurrent)
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return AppColors.success
        } else if isCurrent {
            return AppColors.accentRed
        } else {
            return AppColors.backgroundPrimary
        }
    }
    
    private var borderColor: Color {
        if isCompleted {
            return AppColors.success
        } else if isCurrent {
            return AppColors.accentRed
        } else {
            return AppColors.textTertiary.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        if isCurrent {
            return .white
        } else {
            return AppColors.textSecondary
        }
    }
}

// MARK: - Pill de Información Moderno
struct ModernInfoPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Vista de Día Vacío Moderno
struct ModernEmptyDayView: View {
    let selectedDay: WorkoutDay
    let onAddExercise: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(AppColors.textTertiary)
            
            VStack(spacing: 8) {
                Text("Sin entrenamientos")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("No tienes rutinas programadas para \(selectedDay.displayName.lowercased())")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                HapticManager.shared.buttonTapped()
                onAddExercise()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    
                    Text("Agregar Ejercicios")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [AppColors.accentRed, AppColors.accentRed.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(color: AppColors.accentRed.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Vista de Detalle de Ejercicio Moderna
struct ModernExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Imagen del ejercicio si existe
                    if let imageData = exercise.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.backgroundCard)
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: exercise.sfSymbolIcon ?? "dumbbell.fill")
                                        .font(.system(size: 48, weight: .light))
                                        .foregroundColor(AppColors.textTertiary)
                                    
                                    Text("Sin imagen")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            )
                    }
                    
                    // Información del ejercicio
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Descripción")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(exercise.info.isEmpty ? "No hay descripción disponible." : exercise.info)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    // Detalles técnicos
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Detalles")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        VStack(spacing: 12) {
                            if exercise.repetitions > 0 {
                                ModernDetailRow(icon: "repeat", title: "Repeticiones", value: "\(exercise.repetitions)")
                            }
                            
                            if exercise.weight > 0 {
                                ModernDetailRow(icon: "scalemass", title: "Peso", value: "\(Int(exercise.weight)) kg")
                            }
                            
                            if exercise.segundos > 0 {
                                ModernDetailRow(icon: "timer", title: "Duración", value: "\(exercise.segundos) segundos")
                            }
                            
                            ModernDetailRow(icon: "list.number", title: "Series", value: "\(exercise.totalSets)")
                            ModernDetailRow(icon: "timer.circle", title: "Descanso", value: "\(exercise.restDuration / 60):\(String(format: "%02d", exercise.restDuration % 60))")
                            
                            if !exercise.targetMuscle.isEmpty {
                                ModernDetailRow(icon: "figure.strengthtraining.traditional", title: "Músculo objetivo", value: exercise.targetMuscle)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(AppColors.backgroundPrimary)
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentRed)
                }
            }
        }
    }
}

// MARK: - Fila de Detalle Moderna
struct ModernDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.accentRed)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    WeeklyCalendarView()
        .environmentObject(WorkoutViewModel())
        .environmentObject(ThemeManager())
        .environmentObject(UserManager())
}
