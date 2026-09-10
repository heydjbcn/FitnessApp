//
//  HomeView.swift
//  FitnessApp
//
//  Inicio del rediseño «Pulso»: la sesión del día de un vistazo y los
//  ejercicios listos para ir marcando serie a serie.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    /// Día que se está viendo. Vive en ContentView para que el Calendario
    /// pueda mandar aquí con "Entrenar este día".
    @Binding var selectedDay: WorkoutDay

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager

    @State private var detail: DetailTarget? = nil
    @State private var formDay: FormTarget? = nil

    private var p: Palette { themeManager.p }
    private var today: WorkoutDay { WeeklyCalendarView.getCurrentDay() }
    private var records: [WorkoutExercise] { viewModel.dailyWorkoutRecords[selectedDay] ?? [] }

    var body: some View {
        ZStack(alignment: .top) {
            PulsoBackground(p: p)

            VStack(alignment: .leading, spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        sessionCard
                        daysStrip.padding(.top, 14)
                        quote
                        exercisesHeader
                        exercisesList
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
        }
        .sheet(item: $detail) { target in
            ExerciseDetailSheet(exerciseId: target.exerciseId,
                                workoutExerciseId: target.workoutExerciseId,
                                day: selectedDay)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .sheet(item: $formDay) { target in
            ExerciseFormSheet(editing: nil, prefillDay: target.day)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
    }

    // MARK: - Cabecera fija

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text(saludo)
                    .font(.fig(14, .medium))
                    .foregroundColor(p.mute)
                    .lineLimit(1)
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(p.acc)
                    Text("\(viewModel.consecutiveWorkoutDays()) días")
                        .font(.fig(12, .semibold))
                        .foregroundColor(p.ink)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(p.card))
                .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(selectedDay.displayName)
                    .font(.bri(34))
                    .em(-0.03, size: 34)
                    .foregroundColor(p.ink)
                if let label = viewModel.label(for: selectedDay) {
                    GradientText(text: label, font: .bri(34), p: p, tracking: -0.03 * 34)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .padding(.top, 8)

            if selectedDay != today {
                Button {
                    withAnimation { selectedDay = today }
                    HapticManager.shared.buttonTapped()
                } label: {
                    Text("Estás viendo otro día · Volver a hoy")
                        .font(.fig(12, .semibold))
                        .foregroundColor(p.ink)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Capsule().fill(p.soft))
                        .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
    }

    private var saludo: String {
        let h = Calendar.current.component(.hour, from: Date())
        let g = (6..<12).contains(h) ? "Buenos días" : (12..<22).contains(h) ? "Buenas tardes" : "Buenas noches"
        let nombre = userManager.userName.trimmingCharacters(in: .whitespaces)
        return nombre.isEmpty ? g : "\(g), \(nombre)"
    }

    // MARK: - Tarjeta de sesión

    private var sessionCard: some View {
        let total = viewModel.totalSets(for: selectedDay)
        let done = viewModel.completedSets(for: selectedDay)
        let pct = total > 0 ? Double(done) / Double(total) : 0

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(selectedDay == today ? "Sesión de hoy" : "Sesión del \(selectedDay.displayName.lowercased())")
                    .font(.fig(15, .bold))
                    .foregroundColor(p.ink)
                Spacer()
                GradientText(text: "\(Int((pct * 100).rounded()))%", font: .bri(26), p: p)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(p.soft)
                    Capsule().fill(p.hgrad)
                        .frame(width: geo.size.width * pct)
                        .shadow(color: p.glow1, radius: 8)
                        .animation(.easeOut(duration: 0.5), value: pct)
                }
            }
            .frame(height: 12)
            .padding(.top, 12)

            HStack(spacing: 10) {
                StatTile(label: "Series", value: "\(done)", unit: "/\(total)", p: p)
                StatTile(label: "Tonelaje", value: tonelaje, p: p)
                StatTile(label: "Quedan", value: "\(viewModel.remainingMinutes(for: selectedDay)) min", p: p)
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .pulsoCard(p, radius: 26)
    }

    private var tonelaje: String {
        let kg = viewModel.volume(for: selectedDay)
        return kg >= 1000
            ? String(format: "%.1f t", kg / 1000).replacingOccurrences(of: ".", with: ",")
            : "\(Int(kg.rounded())) kg"
    }

    // MARK: - Tira de días

    /// Los días de entrenamiento más el de hoy (aunque sea de descanso) y el
    /// que se esté viendo: así nunca falta el chip del día de la cabecera.
    private var stripDays: [WorkoutDay] {
        var days = WorkoutDay.allCases.filter { !(viewModel.dailyWorkoutRecords[$0] ?? []).isEmpty }
        if days.isEmpty { days = viewModel.activeDays }
        for d in [today, selectedDay] where !days.contains(d) { days.append(d) }
        return days.sorted { $0.weekOrder < $1.weekOrder }
    }

    private var daysStrip: some View {
        HStack(spacing: 8) {
            ForEach(stripDays) { day in
                DayChip(day: day,
                        isSelected: day == selectedDay,
                        isDone: viewModel.isDayComplete(day),
                        count: (viewModel.dailyWorkoutRecords[day] ?? []).count,
                        p: p) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selectedDay = day }
                    HapticManager.shared.segmentChanged()
                }
            }
        }
    }

    private var quote: some View {
        Text("“\(userManager.getMotivationalQuote())”")
            .font(.fig(13, .medium))
            .italic()
            .lineSpacing(4)
            .foregroundColor(p.mute)
            .padding(.horizontal, 6)
            .padding(.top, 18)
    }

    // MARK: - Ejercicios

    private var exercisesHeader: some View {
        HStack {
            Text("Ejercicios")
                .font(.bri(20))
                .em(-0.02, size: 20)
                .foregroundColor(p.ink)
            Spacer()
            Button {
                HapticManager.shared.buttonTapped()
                formDay = FormTarget(day: selectedDay)
            } label: {
                Text("+ Añadir")
                    .font(.fig(13, .semibold))
                    .foregroundColor(p.acc)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.top, 22)
        .padding(.bottom, 4)
    }

    @ViewBuilder private var exercisesList: some View {
        if records.isEmpty {
            EmptyCard(icon: "dumbbell.fill",
                      title: "Sin ejercicios para el \(selectedDay.displayName.lowercased())",
                      message: "Añade tu primer ejercicio o carga una rutina de ejemplo para ver la app llena.",
                      p: p) {
                PrimaryButton(title: "Añadir ejercicio", p: p) {
                    formDay = FormTarget(day: selectedDay)
                }
                if viewModel.availableExercises.isEmpty {
                    SoftButton(title: "Cargar rutina de ejemplo", p: p) {
                        viewModel.loadSampleRoutine()
                    }
                }
            }
            .padding(.top, 10)
        } else {
            ForEach(records) { record in
                if let exercise = viewModel.getExercise(by: record.exerciseId) {
                    HomeExerciseCard(exercise: exercise, record: record, day: selectedDay, p: p) {
                        detail = DetailTarget(exerciseId: exercise.id, workoutExerciseId: record.id)
                    }
                    .padding(.top, 10)
                }
            }
        }
    }

    struct DetailTarget: Identifiable {
        let exerciseId: UUID
        let workoutExerciseId: UUID
        var id: UUID { workoutExerciseId }
    }

    struct FormTarget: Identifiable {
        let day: WorkoutDay
        var id: String { day.rawValue }
    }
}

// MARK: - Tarjeta de ejercicio

struct HomeExerciseCard: View {
    let exercise: Exercise
    let record: WorkoutExercise
    let day: WorkoutDay
    let p: Palette
    let onOpenDetail: () -> Void

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager

    private var isDone: Bool { record.completedSets >= exercise.totalSets }
    private var isStarted: Bool { record.completedSets > 0 && !isDone }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    ExerciseIcon(exercise: exercise, size: 40, radius: 13, p: p)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(exercise.name)
                            .font(.fig(16, .bold))
                            .em(-0.01, size: 16)
                            .foregroundColor(p.ink)
                            .lineLimit(2)
                        Text(viewModel.meta(for: exercise))
                            .font(.fig(13, .medium))
                            .foregroundColor(p.mute)
                    }
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    if let g = record.supersetGroup {
                        DayTag(text: "SS \(ExerciseDetailSheet.ssLetter(g))", p: p)
                    }
                    if isDone {
                        StatusPill(text: "Hecho", p: p)
                    } else if isStarted {
                        StatusPill(text: "En curso", filled: true, p: p)
                    }
                    Button(action: onOpenDetail) {
                        Image(systemName: "info")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(p.mute)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().strokeBorder(p.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                ForEach(0..<max(0, exercise.totalSets), id: \.self) { index in
                    SetDot(number: index + 1, isDone: index < record.completedSets, p: p) {
                        tapSet(index)
                    }
                }
                Spacer(minLength: 0)
                Button {
                    viewModel.timerLabel = "\(exercise.name) · descanso"
                    viewModel.startTimer(duration: exercise.restDuration,
                                         isEnabled: themeManager.isTimerEnabled)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "timer").font(.system(size: 13, weight: .semibold))
                        Text(WorkoutViewModel.restText(exercise.restDuration)).font(.fig(13, .semibold))
                    }
                    .foregroundColor(p.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(!themeManager.isTimerEnabled)
                .opacity(themeManager.isTimerEnabled ? 1 : 0.4)
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .pulsoCard(p, radius: 22)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpenDetail)
    }

    /// Tocar la siguiente bolita marca la serie (y el modelo arranca el
    /// descanso); tocar la última marcada la deshace.
    private func tapSet(_ index: Int) {
        if index == record.completedSets {
            viewModel.completeSet(for: record.id, in: day)
        } else if index == record.completedSets - 1 {
            viewModel.undoLastSet(for: record.id, in: day)
        }
    }
}
