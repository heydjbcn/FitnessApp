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
        NavigationStack {
            ZStack {
                AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progreso del día seleccionado (movido arriba)
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
                    
                    // Contenido del día seleccionado
                    ScrollView {
                        VStack(spacing: 20) {
                            // Lista de ejercicios
                            if let workoutRecords = viewModel.dailyWorkoutRecords[selectedDay], !workoutRecords.isEmpty {
                                LazyVStack(spacing: 16) {
                                    ForEach(workoutRecords, id: \.id) { workoutRecord in
                                        if let exercise = viewModel.getExercise(by: workoutRecord.exerciseId) {
                                            CalendarExerciseCard(
                                                exercise: exercise,
                                                workoutRecord: workoutRecord,
                                                themeManager: themeManager,
                                                onTimerStart: { duration in
                                                    viewModel.startTimer(duration: duration, isEnabled: themeManager.isTimerEnabled)
                                                }
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .onboardingHighlight(
                                    isHighlighted: viewModel.onboardingManager.showingOnboarding && 
                                                 viewModel.onboardingManager.onboardingStep == 4 &&
                                                 OnboardingManager.onboardingSteps[4].highlightArea == .calendar
                                )
                            } else {
                                // Vista vacía
                                VStack(spacing: 16) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 60))
                                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                    
                                    Text("¡Añade tu primer ejercicio!")
                                        .font(AppFonts.subtitle)
                                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                    
                                    Text("Ve a la pestaña de Añadir Ejercicios para comenzar")
                                        .font(AppFonts.caption)
                                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                        .multilineTextAlignment(.center)
                                    
                                    // Botón para navegar a añadir ejercicios
                                    Button(action: {
                                        HapticManager.shared.buttonTapped()
                                        onNavigateToAddExercise?()
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                                                .font(.system(size: 16))
                                            Text("Añadir Ejercicio")
                                                .font(AppFonts.subtitle)
                                                .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(AppColors.primary(themeManager: themeManager))
                                        .cornerRadius(12)
                                        .shadow(color: AppColors.primary(themeManager: themeManager).opacity(0.3), radius: 4, x: 0, y: 2)
                                    }
                                    .padding(.horizontal, 40)
                                    .padding(.top, 8)
                                }
                                .padding(.top, 60)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                
                // Timer compacto overlay
                if viewModel.timerActive {
                    ZStack {
                        // Fondo semi-transparente
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                viewModel.stopTimer()
                            }
                        
                        VStack {
                            Spacer()
                            CompactTimerView(
                                onStop: {
                                    viewModel.stopTimer()
                                }
                            )
                            .environmentObject(themeManager)
                            .environmentObject(viewModel)
                            .padding(.bottom, 100) // Encima de la barra de tabs
                            Spacer()
                        }
                    }
                }
                }
            }
            .navigationTitle("Calendario Semanal")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Sincronizar el estado del timer con ThemeManager
                viewModel.updateTimerEnabledState(themeManager.isTimerEnabled)
            }
        }
    }
    
    private func dayFullName(for day: WorkoutDay) -> String {
        switch day {
        case .monday: return "Lunes"
        case .tuesday: return "Martes"
        case .wednesday: return "Miércoles"
        case .thursday: return "Jueves"
        case .friday: return "Viernes"
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
            VStack(spacing: 8) {
                Image(systemName: dayIcon(for: day))
                    .font(.title2)
                    .foregroundColor(isSelected ? AppColors.onPrimary(themeManager: themeManager) : AppColors.primary(themeManager: themeManager))

                Text(dayShortName(for: day))
                    .font(AppFonts.caption)
                    .foregroundColor(isSelected ? AppColors.onPrimary(themeManager: themeManager) : AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    .fontWeight(.semibold)

                if exerciseCount > 0 {
                    Text("\(exerciseCount)")
                        .font(AppFonts.caption)
                        .foregroundColor(isSelected ? AppColors.onPrimary(themeManager: themeManager) : AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? AppColors.onPrimary(themeManager: themeManager).opacity(0.3) : AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 8)
            .background(isSelected ? AppColors.primary(themeManager: themeManager) : AppColors.cardBackground(isDark: themeManager.isDarkMode))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary(themeManager: themeManager) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func dayIcon(for day: WorkoutDay) -> String {
        return "calendar" // Todos los días usan el mismo icono
    }
    
    private func dayShortName(for day: WorkoutDay) -> String {
        switch day {
        case .monday: return "Lun"
        case .tuesday: return "Mar"
        case .wednesday: return "Mié"
        case .thursday: return "Jue"
        case .friday: return "Vie"
        }
    }
}

struct CalendarExerciseCard: View {
    let exercise: Exercise
    let workoutRecord: WorkoutExercise
    let themeManager: ThemeManager
    let onTimerStart: (Int) -> Void
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var showingTooltip = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header con nombre y peso
            HStack {
                Text(exercise.name)
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    .fontWeight(.semibold)
                
                // Botón de información para tooltip
                Button(action: {
                    showingTooltip = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                if exercise.weight > 0 {
                    Text("\(Int(exercise.weight)) kg")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.primary(themeManager: themeManager).opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Info de repeticiones/segundos y series
            HStack {
                // Mostrar segundos si están configurados (> 0), sino mostrar repeticiones
                if exercise.segundos > 0 {
                    Label("\(exercise.segundos)s", systemImage: "timer")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                } else if exercise.repetitions > 0 {
                    Label("\(exercise.repetitions) reps", systemImage: "repeat")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                Spacer()
                
                Text("\(exercise.totalSets) series")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            
            // Indicadores de series (bolitas clicables más grandes)
            HStack(spacing: 12) {
                ForEach(0..<exercise.totalSets, id: \.self) { setIndex in
                    Button(action: {
                        toggleSetCompletion(setIndex: setIndex)
                    }) {
                        ZStack {
                            Circle()
                                .fill(setIndex < workoutRecord.completedSets ? AppColors.primary(themeManager: themeManager) : AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.3))
                                .frame(width: 32, height: 32)
                                .scaleEffect(setIndex < workoutRecord.completedSets ? 1.1 : 1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: workoutRecord.completedSets)
                            
                            if setIndex < workoutRecord.completedSets {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                                    .scaleEffect(setIndex < workoutRecord.completedSets ? 1.0 : 0.1)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.1), value: workoutRecord.completedSets)
                            } else {
                                Text("\(setIndex + 1)")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onboardingHighlight(
                    isHighlighted: viewModel.onboardingManager.showingOnboarding && 
                                 viewModel.onboardingManager.onboardingStep == 5 &&
                                 OnboardingManager.onboardingSteps[5].highlightArea == .setButtons
                )
                
                Spacer()
                
                // Botón de timer
                Button(action: {
                    HapticManager.shared.buttonTapped()
                    if themeManager.isTimerEnabled {
                        onTimerStart(exercise.restDuration)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text("\(exercise.restDuration)s")
                    }
                    .font(AppFonts.caption)
                    .foregroundColor(themeManager.isTimerEnabled ? AppColors.onPrimary(themeManager: themeManager) : AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(themeManager.isTimerEnabled ? AppColors.primary(themeManager: themeManager) : AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.3))
                    .cornerRadius(16)
                }
                .disabled(!themeManager.isTimerEnabled)
            }
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
        .alert(exercise.name, isPresented: $showingTooltip) {
            Button("Cerrar", role: .cancel) { }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                if !exercise.info.isEmpty {
                    Text(exercise.info)
                        .font(AppFonts.body)
                }

                if exercise.imageData != nil {
                    Text("📷 Imagen disponible")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                }

                if exercise.info.isEmpty && exercise.imageData == nil {
                    Text("No hay información adicional disponible")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func toggleSetCompletion(setIndex: Int) {
        // Necesitamos encontrar el día para este ejercicio
        if let day = findDayForWorkoutRecord() {
            if setIndex == workoutRecord.completedSets {
                viewModel.completeSet(for: workoutRecord.id, in: day)
                if themeManager.isTimerEnabled {
                    onTimerStart(exercise.restDuration)
                }
            } else if setIndex == workoutRecord.completedSets - 1 {
                viewModel.undoLastSet(for: workoutRecord.id, in: day)
            }
        }
    }
    
    private func findDayForWorkoutRecord() -> WorkoutDay? {
        for day in WorkoutDay.allCases {
            if let records = viewModel.dailyWorkoutRecords[day] {
                if records.contains(where: { $0.id == workoutRecord.id }) {
                    return day
                }
            }
        }
        return nil
    }
}

struct CompactTimerView: View {
    let onStop: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: WorkoutViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Círculo de progreso más grande
            ZStack {
                Circle()
                    .stroke(AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppColors.primary(themeManager: themeManager), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.timeRemaining)
                
                VStack(spacing: 4) {
                    Text("\(viewModel.timeRemaining)")
                        .font(AppFonts.metric)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))

                    Text("segundos")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
            }
            
            VStack(spacing: 12) {
                Text("Descanso")
                    .font(AppFonts.title)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))

                Button("Parar Timer") {
                    viewModel.stopTimer()
                    onStop()
                }
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(AppColors.primary(themeManager: themeManager))
                .cornerRadius(25)
            }
        }
        .padding(32)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 32)
    }
    
    private var progress: CGFloat {
        guard viewModel.currentTimerDuration > 0 else { return 0 }
        return CGFloat(viewModel.currentTimerDuration - viewModel.timeRemaining) / CGFloat(viewModel.currentTimerDuration)
    }
}

struct DailyProgressContainer: View {
    let day: WorkoutDay
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    
    private var dayExercises: [WorkoutExercise] {
        viewModel.dailyWorkoutRecords[day] ?? []
    }
    
    private var totalSets: Int {
        dayExercises.compactMap { record in
            viewModel.getExercise(by: record.exerciseId)?.totalSets
        }.reduce(0, +)
    }
    
    private var completedSets: Int {
        dayExercises.map { $0.completedSets }.reduce(0, +)
    }
    
    private var totalWeight: Double {
        dayExercises.compactMap { record in
            if let exercise = viewModel.getExercise(by: record.exerciseId) {
                return exercise.weight * Double(record.completedSets)
            }
            return 0
        }.reduce(0, +)
    }
    
    private var totalReps: Int {
        dayExercises.compactMap { record in
            if let exercise = viewModel.getExercise(by: record.exerciseId) {
                return exercise.repetitions * record.completedSets
            }
            return 0
        }.reduce(0, +)
    }
    
    private var estimatedMinutes: Int {
        return totalSets * 3 // 3 minutos por serie estimado
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Título
            Text("Progreso \(dayDisplayName(for: day))")
                .font(AppFonts.title)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            
            // Anillos de progreso (mismo diseño que progreso semanal)
            HStack(spacing: 25) {
                // Repeticiones (azul)
                ProgressRing(
                    value: Double(totalReps),
                    maxValue: Double(totalSets * 25), // Estimado 25 reps por serie
                    color: .blue,
                    title: "Reps",
                    subtitle: "\(totalReps)"
                )
                
                // Peso total (rojo) - Ahora en toneladas
                ProgressRing(
                    value: totalWeight / 1000, // Convertir kg a toneladas
                    maxValue: Double(totalSets * 100) / 1000, // Estimado 100kg por serie en toneladas
                    color: .red,
                    title: "Tonelaje",
                    subtitle: String(format: "%.2ft", totalWeight / 1000) // Mostrar en toneladas con 2 decimales
                )
                
                // Series (verde)
                ProgressRing(
                    value: Double(completedSets),
                    maxValue: Double(totalSets > 0 ? totalSets : 1),
                    color: .green,
                    title: "Series",
                    subtitle: "\(completedSets)"
                )
                
                // Tiempo (morado)
                ProgressRing(
                    value: Double(estimatedMinutes),
                    maxValue: Double(totalSets * 5), // Máximo 5 min por serie
                    color: .purple,
                    title: "Tiempo",
                    subtitle: "\(estimatedMinutes)min"
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground(isDark: themeManager.isDarkMode).opacity(0.85))
        )
    }
    
    private func dayDisplayName(for day: WorkoutDay) -> String {
        switch day {
        case .monday: return "Lunes"
        case .tuesday: return "Martes"
        case .wednesday: return "Miércoles"
        case .thursday: return "Jueves"
        case .friday: return "Viernes"
        }
    }
}

// Componente ProgressRing (igual al de la pantalla principal)
struct ProgressRing: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let title: String
    let subtitle: String
    
    private var progress: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 6)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: progress)
                
                Text(subtitle)
                    .font(AppFonts.subtitle)
                    .foregroundColor(.white)
            }

            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview {
    WeeklyCalendarView()
        .environmentObject(WorkoutViewModel())
        .environmentObject(ThemeManager())
        .environmentObject(UserManager())
}
