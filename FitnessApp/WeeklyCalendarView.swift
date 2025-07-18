import SwiftUI

struct WeeklyCalendarView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @State private var selectedDay: WorkoutDay = .monday
    @State private var showingCompactTimer = false
    @State private var timerDuration = 60
    
    private var daysWithExercises: [WorkoutDay] {
        WorkoutDay.allCases.sorted { d1, d2 in
            WorkoutDay.allCases.firstIndex(of: d1)! < WorkoutDay.allCases.firstIndex(of: d2)!
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
                                exerciseCount: viewModel.exercises[day]?.count ?? 0,
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
                            if let exercises = viewModel.exercises[selectedDay], !exercises.isEmpty {
                                LazyVStack(spacing: 16) {
                                    ForEach(exercises, id: \.id) { exercise in
                                        CalendarExerciseCard(
                                            exercise: exercise,
                                            themeManager: themeManager,
                                            onTimerStart: { duration in
                                                timerDuration = duration
                                                showingCompactTimer = true
                                                viewModel.startTimer(duration: duration)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
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
                                }
                                .padding(.top, 60)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                
                // Timer compacto overlay
                if showingCompactTimer {
                    ZStack {
                        // Fondo semi-transparente
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingCompactTimer = false
                                viewModel.stopTimer()
                            }
                        
                        VStack {
                            Spacer()
                            CompactTimerView(
                                duration: timerDuration,
                                onStop: {
                                    showingCompactTimer = false
                                    viewModel.stopTimer()
                                }
                            )
                            .environmentObject(themeManager)
                            .padding(.bottom, 100) // Encima de la barra de tabs
                            Spacer()
                        }
                    }
                }
                }
            }
            .navigationTitle("Calendario Semanal")
            .navigationBarTitleDisplayMode(.inline)
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
                    .foregroundColor(isSelected ? .white : AppColors.primary)
                
                Text(dayShortName(for: day))
                    .font(AppFonts.caption)
                    .foregroundColor(isSelected ? .white : AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    .fontWeight(.semibold)
                
                if exerciseCount > 0 {
                    Text("\(exerciseCount)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white : AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 8)
            .background(isSelected ? AppColors.primary : AppColors.cardBackground(isDark: themeManager.isDarkMode))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
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
    let themeManager: ThemeManager
    let onTimerStart: (Int) -> Void
    @EnvironmentObject var viewModel: WorkoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header con nombre y peso
            HStack {
                Text(exercise.name)
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    .fontWeight(.semibold)
                
                Spacer()
                
                if exercise.weight > 0 {
                    Text("\(Int(exercise.weight)) kg")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Info de repeticiones y series
            HStack {
                Label("\(exercise.repetitions) reps", systemImage: "repeat")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                
                Spacer()
                
                Text("\(exercise.totalSets) sets")
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
                                .fill(setIndex < exercise.completedSets ? AppColors.primary : AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.3))
                                .frame(width: 32, height: 32)
                            
                            if setIndex < exercise.completedSets {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(setIndex + 1)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // Botón de timer
                Button(action: {
                    onTimerStart(exercise.restDuration)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text("\(exercise.restDuration)s")
                    }
                    .font(AppFonts.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.primary)
                    .cornerRadius(16)
                }
            }
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
    
    private func toggleSetCompletion(setIndex: Int) {
        viewModel.toggleSetCompletion(exercise: exercise, setIndex: setIndex)
        
        // Iniciar timer automáticamente al completar una serie
        if setIndex == exercise.completedSets {
            onTimerStart(exercise.restDuration)
        }
    }
}

struct CompactTimerView: View {
    let duration: Int
    let onStop: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    
    init(duration: Int, onStop: @escaping () -> Void) {
        self.duration = duration
        self.onStop = onStop
        self._timeRemaining = State(initialValue: duration)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Círculo de progreso más grande
            ZStack {
                Circle()
                    .stroke(AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                
                VStack(spacing: 4) {
                    Text("\(timeRemaining)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Text("segundos")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
            }
            
            VStack(spacing: 12) {
                Text("Descanso")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Button("Parar Timer") {
                    stopTimer()
                    onStop()
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(AppColors.primary)
                .cornerRadius(25)
            }
        }
        .padding(32)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 32)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private var progress: CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(duration - timeRemaining) / CGFloat(duration)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                onStop()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct DailyProgressContainer: View {
    let day: WorkoutDay
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    
    private var dayExercises: [Exercise] {
        viewModel.exercises[day] ?? []
    }
    
    private var totalSets: Int {
        dayExercises.map { $0.totalSets }.reduce(0, +)
    }
    
    private var completedSets: Int {
        dayExercises.map { $0.completedSets }.reduce(0, +)
    }
    
    private var totalWeight: Double {
        dayExercises.map { $0.weight * Double($0.completedSets) }.reduce(0, +)
    }
    
    private var totalReps: Int {
        dayExercises.map { $0.repetitions * $0.completedSets }.reduce(0, +)
    }
    
    private var estimatedMinutes: Int {
        return totalSets * 3 // 3 minutos por serie estimado
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Título
            Text("Progreso \(dayDisplayName(for: day))")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
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
                
                // Peso total (rojo)
                ProgressRing(
                    value: totalWeight,
                    maxValue: Double(totalSets * 100), // Estimado 100kg por serie
                    color: .red,
                    title: "Peso",
                    subtitle: "\(Int(totalWeight))kg"
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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
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
