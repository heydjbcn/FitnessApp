//
//  HomeView.swift
//  FitnessApp
//
//  Pantalla de Inicio del rediseño «Pulso»: la sesión del día de un vistazo
//  —cuánto llevas, cuánto pesa y cuánto queda— y los ejercicios listos para
//  ir marcando serie a serie.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager

    @State private var selectedDay: WorkoutDay = WeeklyCalendarView.getCurrentDay()
    @State private var detail: DetailTarget? = nil
    @State private var showingCoach = false
    @State private var showingSettings = false

    private var isDark: Bool { themeManager.isDarkMode }
    private var accent: AccentColor { themeManager.selectedAccentColor }
    private var today: WorkoutDay { WeeklyCalendarView.getCurrentDay() }
    private var records: [WorkoutExercise] { viewModel.dailyWorkoutRecords[selectedDay] ?? [] }

    var body: some View {
        ZStack {
            Pulso.background(isDark: isDark).ignoresSafeArea()
            accentGlow

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Pulso.Space.stack) {
                    greeting
                    dayTitle
                    sessionCard
                    daysStrip
                    quote
                    exercisesSection
                }
                .padding(.horizontal, Pulso.Space.screen)
                .padding(.bottom, 100)
            }
        }
        .sheet(item: $detail) { target in
            NavigationStack {
                ExerciseDetailSheet(exerciseId: target.exerciseId,
                                    workoutExerciseId: target.workoutExerciseId,
                                    day: selectedDay)
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
            }
        }
        .sheet(isPresented: $showingCoach) {
            CoachAIView()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingSettings) {
            ProgramSettingsView()
                .environmentObject(themeManager)
                .environmentObject(userManager)
                .environmentObject(viewModel)
        }
    }

    // Resplandor del acento detrás de la cabecera, como en el prototipo.
    private var accentGlow: some View {
        VStack {
            Circle()
                .fill(accent.gradient(isDark: isDark))
                .frame(width: 320, height: 320)
                .blur(radius: 110)
                .opacity(isDark ? 0.30 : 0.18)
                .offset(y: -170)
            Spacer()
        }
        .ignoresSafeArea()
    }

    // MARK: - Cabecera

    private var greeting: some View {
        HStack(alignment: .center) {
            Text(saludo)
                .font(AppFonts.body)
                .foregroundColor(Pulso.mute(isDark: isDark))

            Spacer()

            if viewModel.consecutiveWorkoutDays() > 0 {
                PulsoPill(text: "\(viewModel.consecutiveWorkoutDays()) días",
                          icon: "flame.fill", accent: accent, isDark: isDark)
            }

            Button { HapticManager.shared.buttonTapped(); showingCoach = true } label: {
                circleIcon("sparkles")
            }
            Button { HapticManager.shared.buttonTapped(); showingSettings = true } label: {
                circleIcon("gearshape.fill")
            }
        }
        .padding(.top, 8)
    }

    private var saludo: String {
        let nombre = userManager.userName.trimmingCharacters(in: .whitespaces)
        return nombre.isEmpty ? userManager.getGreeting() : "\(userManager.getGreeting()), \(nombre)"
    }

    private func circleIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(accent.accent(isDark: isDark))
            .frame(width: 38, height: 38)
            .background(Circle().fill(Pulso.card(isDark: isDark)))
            .overlay(Circle().strokeBorder(Pulso.line(isDark: isDark), lineWidth: 1))
    }

    /// Día grande y, debajo, el nombre que el usuario le haya puesto a la sesión.
    private var dayTitle: some View {
        VStack(alignment: .leading, spacing: -2) {
            Text(selectedDay.displayName)
                .font(AppFonts.largeTitle)
                .foregroundColor(Pulso.ink(isDark: isDark))
            if let label = viewModel.label(for: selectedDay) {
                GradientText(text: label, font: AppFonts.largeTitle, accent: accent, isDark: isDark)
            }
            if selectedDay != today {
                Button {
                    withAnimation { selectedDay = today }
                    HapticManager.shared.buttonTapped()
                } label: {
                    Text("Estás viendo otro día · Volver a hoy")
                        .font(AppFonts.caption)
                        .foregroundColor(accent.accent(isDark: isDark))
                }
                .padding(.top, 6)
            }
        }
    }

    // MARK: - Tarjeta de la sesión

    private var sessionCard: some View {
        let total = viewModel.totalSets(for: selectedDay)
        let done = viewModel.completedSets(for: selectedDay)
        let progress = total > 0 ? Double(done) / Double(total) : 0

        return GlassCard(isDark: isDark) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(selectedDay == today ? "Sesión de hoy" : "Sesión del \(selectedDay.displayName.lowercased())")
                        .font(AppFonts.subtitle)
                        .foregroundColor(Pulso.ink(isDark: isDark))
                    Spacer()
                    GradientText(text: "\(Int(progress * 100))%", font: AppFonts.metric,
                                 accent: accent, isDark: isDark)
                }

                PulsoProgressBar(value: progress, accent: accent, isDark: isDark)

                HStack(spacing: 10) {
                    StatTile(label: "Series", value: "\(done)", unit: "/\(total)", isDark: isDark)
                    StatTile(label: "Tonelaje", value: tonelaje, isDark: isDark)
                    StatTile(label: "Quedan", value: "\(viewModel.remainingMinutes(for: selectedDay))",
                             unit: "min", isDark: isDark)
                }
            }
        }
    }

    private var tonelaje: String {
        let kg = viewModel.volume(for: selectedDay)
        if kg >= 1000 {
            return String(format: "%.1f t", kg / 1000).replacingOccurrences(of: ".", with: ",")
        }
        return "\(Int(kg)) kg"
    }

    // MARK: - Tira de días

    /// Días que se ven en la tira: los activos, más el de hoy aunque sea de
    /// descanso (si no, la cabecera dice "Jueves" y no hay ningún chip de jueves).
    private var stripDays: [WorkoutDay] {
        var days = viewModel.activeDays
        if !days.contains(today) { days.append(today) }
        if !days.contains(selectedDay) { days.append(selectedDay) }
        return days.sorted { $0.weekOrder < $1.weekOrder }
    }

    private var daysStrip: some View {
        HStack(spacing: 8) {
            ForEach(stripDays) { day in
                DayChip(day: day,
                        isSelected: day == selectedDay,
                        isDone: viewModel.isDayComplete(day),
                        count: (viewModel.dailyWorkoutRecords[day] ?? []).count,
                        accent: accent,
                        isDark: isDark) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selectedDay = day }
                    HapticManager.shared.segmentChanged()
                }
            }
        }
    }

    private var quote: some View {
        Text("“\(userManager.getMotivationalQuote())”")
            .font(AppFonts.body)
            .italic()
            .foregroundColor(Pulso.mute(isDark: isDark))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
    }

    // MARK: - Ejercicios del día

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Ejercicios", actionLabel: "+ Añadir",
                          accent: accent, isDark: isDark) {
                HapticManager.shared.buttonTapped()
                selectedTab = 2
            }

            if records.isEmpty {
                GlassCard(isDark: isDark) {
                    VStack(spacing: 14) {
                        PulsoEmptyState(
                            icon: "figure.strengthtraining.traditional",
                            title: "Sin ejercicios para el \(selectedDay.displayName.lowercased())",
                            message: "Añade tu primer ejercicio para empezar a llenar la sesión.",
                            isDark: isDark)
                        PulsoPrimaryButton(title: "Añadir ejercicio", icon: "plus",
                                           accent: accent, isDark: isDark) {
                            HapticManager.shared.buttonTapped()
                            selectedTab = 2
                        }
                    }
                }
            } else {
                ForEach(records) { record in
                    if let exercise = viewModel.getExercise(by: record.exerciseId) {
                        HomeExerciseCard(exercise: exercise, record: record, day: selectedDay,
                                         accent: accent, isDark: isDark) {
                            detail = DetailTarget(exerciseId: exercise.id, workoutExerciseId: record.id)
                        }
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                    }
                }
            }
        }
    }

    /// Identifica qué ejercicio abre la hoja de detalle.
    struct DetailTarget: Identifiable {
        let exerciseId: UUID
        let workoutExerciseId: UUID
        var id: UUID { workoutExerciseId }
    }
}

// MARK: - Tarjeta de ejercicio

struct HomeExerciseCard: View {
    let exercise: Exercise
    let record: WorkoutExercise
    let day: WorkoutDay
    let accent: AccentColor
    let isDark: Bool
    let onOpenDetail: () -> Void

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager

    private var isDone: Bool { record.completedSets >= exercise.totalSets }
    private var isStarted: Bool { record.completedSets > 0 && !isDone }

    var body: some View {
        GlassCard(isDark: isDark) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    icon

                    VStack(alignment: .leading, spacing: 3) {
                        Text(exercise.name)
                            .font(AppFonts.subtitle)
                            .foregroundColor(Pulso.ink(isDark: isDark))
                            .lineLimit(1)
                        Text(subtitle)
                            .font(AppFonts.caption)
                            .foregroundColor(Pulso.mute(isDark: isDark))
                    }

                    Spacer(minLength: 4)

                    if isDone {
                        PulsoPill(text: "Hecho", accent: accent, isDark: isDark)
                    } else if isStarted {
                        PulsoPill(text: "En curso", filled: true, accent: accent, isDark: isDark)
                    }

                    Button(action: onOpenDetail) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 17))
                            .foregroundColor(Pulso.mute(isDark: isDark))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    ForEach(0..<max(0, exercise.totalSets), id: \.self) { index in
                        SetDot(isDone: index < record.completedSets, accent: accent, isDark: isDark) {
                            tapSet(index)
                        }
                    }

                    Spacer(minLength: 0)

                    // Descanso del ejercicio: arranca el temporizador a mano.
                    Button {
                        HapticManager.shared.timerStarted()
                        viewModel.startTimer(duration: exercise.restDuration,
                                             isEnabled: themeManager.isTimerEnabled)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "timer").font(.system(size: 12, weight: .semibold))
                            Text(restLabel).font(AppFonts.label)
                        }
                        .foregroundColor(Pulso.ink(isDark: isDark))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Pulso.soft(isDark: isDark)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!themeManager.isTimerEnabled)
                    .opacity(themeManager.isTimerEnabled ? 1 : 0.4)
                }
            }
        }
    }

    private var icon: some View {
        Group {
            if let data = exercise.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Image(systemName: exercise.sfSymbolIcon ?? "dumbbell.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(accent.accent(isDark: isDark))
            }
        }
        .frame(width: 42, height: 42)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Pulso.soft(isDark: isDark)))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var subtitle: String {
        var parts = ["\(exercise.totalSets) series"]
        if exercise.segundos > 0 {
            parts.append("\(exercise.segundos) s")
        } else if exercise.repetitions > 0 {
            parts.append("\(exercise.repetitions) reps")
        }
        if exercise.weight > 0 { parts.append("\(Int(exercise.weight)) kg") }
        return parts.joined(separator: " · ")
    }

    private var restLabel: String {
        let m = exercise.restDuration / 60, s = exercise.restDuration % 60
        return m > 0 ? String(format: "%d:%02d", m, s) : "\(s)s"
    }

    /// Tocar la siguiente bolita marca la serie; tocar la última marcada la deshace.
    private func tapSet(_ index: Int) {
        if index == record.completedSets {
            viewModel.completeSet(for: record.id, in: day)
        } else if index == record.completedSets - 1 {
            viewModel.undoLastSet(for: record.id, in: day)
        }
    }
}
