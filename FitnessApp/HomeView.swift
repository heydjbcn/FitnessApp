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
    @State private var training = false
    @State private var editingProfile = false
    @State private var editingEquipment = false
    @State private var showingDeadline = false
    @State private var showingIntervals = false
    @State private var showingMobility = false
    @AppStorage("profileNudgeDismissed", store: AppDefaults.store) private var profileNudgeDismissed = false

    private var p: Palette { themeManager.p }
    /// La sesión que toca hoy (no siempre es el día de la semana: ver el modo de la rutina).
    private var today: WorkoutDay { viewModel.todaySession }
    private var records: [WorkoutExercise] { viewModel.dailyWorkoutRecords[selectedDay] ?? [] }

    var body: some View {
        ZStack(alignment: .top) {
            PulsoBackground(p: p)

            VStack(alignment: .leading, spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        sessionCard
                        ProgramBanner(p: p).padding(.top, 12)
                        ExperimentBanner(p: p).padding(.top, 12)
                        RecoveryCard(p: p).padding(.top, 12)
                        if !viewModel.trainingProfile.completed && !profileNudgeDismissed {
                            profileNudge.padding(.top, 12)
                        }
                        daysStrip.padding(.top, 14)
                        quote
                        exercisesHeader
                        exercisesList
                        otherWorkouts.padding(.top, 20)
                        NutritionCard(p: p).padding(.top, 12)
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
        .sheet(isPresented: $editingProfile) {
            TrainingProfileSheet()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingIntervals) {
            IntervalsSheet().environmentObject(viewModel).environmentObject(themeManager)
        }
        .sheet(isPresented: $showingMobility) {
            MobilitySheet(linkDay: selectedDay).environmentObject(viewModel).environmentObject(themeManager)
        }
        .sheet(isPresented: $showingDeadline) {
            TimeBudgetSheet(day: selectedDay)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $editingEquipment) {
            TrainingProfileSheet(initialSection: 3)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .fullScreenCover(isPresented: $training) {
            WorkoutSessionView(day: selectedDay)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
    }

    /// Para quien ya usaba la app antes del perfil: una vez, y se puede cerrar.
    private var profileNudge: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 16, weight: .semibold)).foregroundColor(p.onacc)
                .frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(p.grad))
            VStack(alignment: .leading, spacing: 2) {
                Text("Cuéntanos cómo entrenas").font(.fig(15, .bold)).foregroundColor(p.ink)
                Text("Objetivo, nivel y material: el coach y las rutinas con IA lo tendrán en cuenta.")
                    .font(.fig(12, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button { withAnimation { profileNudgeDismissed = true } } label: {
                Image(systemName: "xmark").font(.system(size: 11, weight: .bold)).foregroundColor(p.mute)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar aviso de perfil")
        }
        .padding(14)
        .pulsoCard(p, radius: 20)
        .contentShape(Rectangle())
        .onTapGesture { editingProfile = true }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.profileNudge")
    }

    // MARK: - Cabecera fija

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text((saludo).loc)
                    .font(.fig(14, .medium))
                    .foregroundColor(p.mute)
                    .lineLimit(1)
                Spacer(minLength: 0)
                WeekGoalRing(done: viewModel.weekStats().sessions, goal: viewModel.weeklySessionGoal, p: p)
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(p.acc)
                    Text((Self.streakText(viewModel.consecutiveWorkoutDays())).loc)
                        .font(.fig(12, .semibold))
                        .foregroundColor(p.ink)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(p.card))
                .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 0) {
                Text((viewModel.slotName(selectedDay)).loc)
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

            if let hint = viewModel.sessionHint(for: selectedDay) {
                Text((hint).loc)
                    .font(.fig(13, .medium)).foregroundColor(p.mute)
                    .padding(.top, 4)
                    .accessibilityIdentifier("home.hint")
            }

            HStack(spacing: 8) {
                equipmentMenu
                if selectedDay != today {
                    Button {
                        withAnimation { selectedDay = today }
                        HapticManager.shared.buttonTapped()
                    } label: {
                        Text(viewModel.scheduleMode == .fixedWeek ? "Estás viendo otro día · Volver a hoy" : "Volver a la de hoy")
                            .font(.fig(12, .semibold))
                            .foregroundColor(p.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(Capsule().fill(p.soft))
                            .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
    }

    /// Dónde entrenas hoy: cambia las alternativas y las rutinas que se proponen.
    private var equipmentMenu: some View {
        Menu {
            Picker("Material", selection: Binding(get: { viewModel.activeEquipment.id },
                                                  set: { viewModel.setActiveEquipment($0); HapticManager.shared.selectionFeedback() })) {
                ForEach(viewModel.equipmentProfiles) { e in
                    Text((e.name).loc).tag(e.id)
                }
            }
            .pickerStyle(.inline)
            Button("Editar material…", systemImage: "slider.horizontal.3") { editingEquipment = true }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse").font(.system(size: 11, weight: .semibold)).foregroundColor(p.acc)
                Text((viewModel.activeEquipment.name).loc).font(.fig(12, .semibold)).foregroundColor(p.ink).lineLimit(1)
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold)).foregroundColor(p.mute)
            }
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(Capsule().fill(p.card))
            .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
        }
        .accessibilityIdentifier("home.equipment")
        .accessibilityLabel("Material: \(viewModel.activeEquipment.name)")
    }

    private var saludo: String {
        let h = Calendar.current.component(.hour, from: Date())
        let g = ((6..<12).contains(h) ? "Buenos días" : (12..<22).contains(h) ? "Buenas tardes" : "Buenas noches").loc
        let nombre = userManager.userName.trimmingCharacters(in: .whitespaces)
        return nombre.isEmpty ? g : "\(g), \(nombre)"
    }

    /// "1 día", "5 días".
    static func streakText(_ n: Int) -> String { n == 1 ? "1 día" : String(localized: "\(n) días") }

    // MARK: - Tarjeta de sesión

    private var sessionCard: some View {
        let total = viewModel.totalSets(for: selectedDay)
        let done = viewModel.completedSets(for: selectedDay)
        let pct = total > 0 ? Double(done) / Double(total) : 0

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text((selectedDay == today ? "Sesión de hoy"
                     : viewModel.scheduleMode == .sequence ? viewModel.slotName(selectedDay)
                     : String(localized: "Sesión del \(selectedDay.displayName.lowercased())")).loc)
                    .font(.fig(15, .bold))
                    .foregroundColor(p.ink)
                Spacer()
                GradientText(text: String(localized: "\(Int((pct * 100).rounded()))%"), font: .bri(26), p: p)
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
                StatTile(label: "Quedan", value: String(localized: "\(viewModel.remainingMinutes(for: selectedDay)) min"), p: p)
            }
            .padding(.top, 16)

            if total > 0 && done < total {
                PrimaryButton(title: done == 0 ? "Empezar entreno" : "Seguir entreno", icon: "play.fill",
                              height: 48, p: p) { training = true }
                    .padding(.top, 14)
                    .accessibilityIdentifier("home.startWorkout")
            }
            if selectedDay == today && total > 0 && done < total { timeRow }
            // Semana flexible: si hoy no se puede, la sesión queda pendiente.
            if viewModel.scheduleMode == .elasticWeek && selectedDay == today && done == 0 && total > 0 {
                let postponed = viewModel.isPostponed()
                Button(postponed ? "Deshacer «hoy no puedo»" : "Hoy no puedo") {
                    viewModel.postponeToday(!postponed)
                    HapticManager.shared.buttonTapped()
                }
                .font(.fig(13, .semibold)).foregroundColor(p.mute)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .accessibilityIdentifier("home.postpone")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .pulsoCard(p, radius: 26)
    }

    /// Intervalos y movilidad, fuera de la rutina.
    private var otherWorkouts: some View {
        VStack(alignment: .leading, spacing: 10) {
            UpperLabel(text: "Otros entrenos", p: p)
            HStack(spacing: 10) {
                quickTile("Intervalos", "HIIT, Tabata, EMOM", "figure.highintensity.intervaltraining") { showingIntervals = true }
                    .accessibilityIdentifier("home.hiit")
                quickTile("Movilidad", viewModel.warmupLink(selectedDay).map { "Calienta: \($0.name)" } ?? "Y calentamientos",
                          "figure.flexibility") { showingMobility = true }
                    .accessibilityIdentifier("home.mobility")
            }
        }
    }

    private func quickTile(_ title: String, _ sub: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundColor(p.acc)
                Text((title).loc).font(.fig(15, .bold)).foregroundColor(p.ink)
                Text((sub).loc).font(.fig(12, .medium)).foregroundColor(p.mute).lineLimit(1)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pulsoCard(p, radius: 20)
        }
        .buttonStyle(.plain)
    }

    /// Recuperación en rojo (Salud), o forzada en pruebas.
    private var lowRecovery: Bool {
        AppDefaults.has("--low-recovery") || (HealthManager.shared.isAvailable && HealthManager.shared.recovery.level == .easy)
    }

    /// «Tengo hasta…» y, con la recuperación en rojo, «Hoy me cuesta».
    private var timeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button { showingDeadline = true } label: {
                    Label((viewModel.sessionDeadline.map { String(localized: "Hasta las \(TimeBudgetSheet.time($0))") } ?? "Tengo hasta…").loc, systemImage: "clock")
                        .font(.fig(13, .semibold)).foregroundColor(p.ink)
                        .padding(.horizontal, 12).frame(height: 34)
                        .background(Capsule().fill(p.soft))
                        .overlay(Capsule().strokeBorder(viewModel.isRunningLate(selectedDay) ? p.danger : p.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home.deadline")
                if viewModel.isLightToday {
                    Button { viewModel.clearSessionTargets(selectedDay) } label: {
                        Label("Versión ligera · Deshacer", systemImage: "leaf.fill")
                            .font(.fig(13, .semibold)).foregroundColor(p.ink)
                            .padding(.horizontal, 12).frame(height: 34)
                            .background(Capsule().fill(p.soft))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.light.undo")
                } else if lowRecovery {
                    Button { viewModel.lightenSession(selectedDay); HapticManager.shared.success() } label: {
                        Label("Hoy me cuesta", systemImage: "leaf")
                            .font(.fig(13, .semibold)).foregroundColor(p.onacc)
                            .padding(.horizontal, 12).frame(height: 34)
                            .background(Capsule().fill(p.hgrad))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.light")
                }
            }
            if let d = viewModel.sessionDeadline {
                let finish = Date().addingTimeInterval(viewModel.remainingSeconds(selectedDay))
                Text((viewModel.isRunningLate(selectedDay)
                     ? String(localized: "Vas tarde: acabarías a las \(TimeBudgetSheet.time(finish)) (límite \(TimeBudgetSheet.time(d))). Toca para recortar.")
                     : String(localized: "Acabas hacia las \(TimeBudgetSheet.time(finish)).")).loc)
                    .font(.fig(12, .medium)).foregroundColor(viewModel.isRunningLate(selectedDay) ? p.danger : p.mute)
                    .accessibilityIdentifier("home.deadline.status")
            }
        }
        .padding(.top, 12)
    }

    private var tonelaje: String {
        let kg = viewModel.volume(for: selectedDay)
        return Units.tonnage(kg)
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
                        title: viewModel.slotShort(day),
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
                      title: String(localized: "Sin ejercicios para el \(selectedDay.displayName.lowercased())"),
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
            // Los ejercicios de una misma superserie van juntos, bajo su cabecera.
            ForEach(Array(groupedRecords.enumerated()), id: \.offset) { _, group in
                if group.count > 1, let g = group.first?.supersetGroup {
                    HStack(spacing: 8) {
                        DayTag(text: String(localized: "Superserie \(ExerciseDetailSheet.ssLetter(g))"), icon: "arrow.triangle.2.circlepath", filled: true, p: p)
                        Text("sin descanso entre ellos")
                            .font(.fig(12, .medium))
                            .foregroundColor(p.mute)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 14)
                }
                ForEach(group) { record in
                    if let exercise = viewModel.getExercise(by: record.exerciseId) {
                        HomeExerciseCard(exercise: exercise, record: record, day: selectedDay, p: p) {
                            detail = DetailTarget(exerciseId: exercise.id, workoutExerciseId: record.id)
                        }
                        .padding(.top, group.count > 1 ? 8 : 10)
                        .padding(.leading, group.count > 1 ? 10 : 0)
                        .overlay(alignment: .leading) {
                            if group.count > 1 {
                                Capsule().fill(p.hgrad).frame(width: 3).padding(.top, 8)
                            }
                        }
                    }
                }
            }
        }
    }

    /// Los registros del día, con los de una misma superserie consecutivos y agrupados.
    private var groupedRecords: [[WorkoutExercise]] {
        var groups: [[WorkoutExercise]] = []
        var seen: Set<Int> = []
        for record in records {
            if let g = record.supersetGroup {
                if seen.contains(g) { continue }
                seen.insert(g)
                groups.append(records.filter { $0.supersetGroup == g })
            } else {
                groups.append([record])
            }
        }
        return groups
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
    @State private var editing: EditTarget? = nil
    @State private var timing = false

    private var isDone: Bool { record.completedSets >= record.planned(exercise) }
    private var isStarted: Bool { record.completedSets > 0 && !isDone }

    var body: some View {
        card
            .sheet(item: $editing) { target in editor(target) }
            .sheet(isPresented: $timing) {
                TimedSetSheet(exercise: exercise, setNumber: record.completedSets + 1, p: p) {
                    viewModel.completeSet(for: record.id, in: day, reps: exercise.segundos)
                }
            }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    ExerciseIcon(exercise: exercise, size: 40, radius: 13, p: p)
                    VStack(alignment: .leading, spacing: 3) {
                        Text((exercise.name).loc)
                            .font(.fig(16, .bold))
                            .em(-0.01, size: 16)
                            .foregroundColor(p.ink)
                            .lineLimit(2)
                        Text((viewModel.meta(for: exercise)).loc)
                            .font(.fig(13, .medium))
                            .foregroundColor(p.mute)
                        if let note = exercise.setupText {
                            Label(note, systemImage: "wrench.adjustable")
                                .font(.fig(12, .medium))
                                .foregroundColor(p.mute)
                                .lineLimit(1)
                        }
                        if record.completedSets == 0, let s = viewModel.suggestion(for: exercise) {
                            Button { editing = EditTarget(index: 0) } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: s.arrow).font(.system(size: 10, weight: .heavy))
                                    Text("Hoy \(s.text)").font(.fig(12, .bold))
                                }
                                .foregroundColor(s.trend == .up ? p.onacc : p.ink)
                                .padding(.horizontal, 9).frame(height: 24)
                                .background(Capsule().fill(s.trend == .up ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 3)
                            .accessibilityIdentifier("suggestion.\(exercise.name)")
                            .accessibilityLabel(String(localized: "Sugerencia de hoy: \(s.text). \(s.reason)"))
                        }
                    }
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    if let g = record.supersetGroup {
                        DayTag(text: String(localized: "SS \(ExerciseDetailSheet.ssLetter(g))"), p: p)
                    }
                    if record.targetSets == 0 && record.completedSets == 0 {
                        StatusPill(text: "Fuera hoy", p: p)
                    } else if isDone {
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
                    .accessibilityIdentifier("info.\(exercise.name)")
                    .accessibilityLabel(String(localized: "Detalle de \(exercise.name)"))
                }
            }

            HStack(spacing: 8) {
                ForEach(0..<max(record.completedSets, record.planned(exercise)), id: \.self) { index in
                    SetDot(number: index + 1, isDone: index < record.completedSets, p: p,
                           onLongPress: { editing = EditTarget(index: index) }) {
                        tapSet(index)
                    }
                    .accessibilityIdentifier("set.\(exercise.name).\(index + 1)")
                    .accessibilityLabel(String(localized: "Serie \(index + 1) de \(exercise.name)"))
                    .accessibilityValue(index < record.completedSets ? "hecha" : "pendiente")
                }
                Spacer(minLength: 0)
                Button {
                    viewModel.timerLabel = String(localized: "\(exercise.name) · descanso")
                    viewModel.startTimer(duration: exercise.restDuration,
                                         isEnabled: themeManager.isTimerEnabled)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "timer").font(.system(size: 13, weight: .semibold))
                        Text((WorkoutViewModel.restText(exercise.restDuration)).loc).font(.fig(13, .semibold))
                    }
                    .foregroundColor(p.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("rest.\(exercise.name)")
                .accessibilityLabel(String(localized: "Empezar descanso de \(WorkoutViewModel.restText(exercise.restDuration))"))
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

    struct EditTarget: Identifiable {
        let index: Int
        var id: Int { index }
    }

    /// Pulsación larga en una bolita: editar esa serie, o marcar la siguiente
    /// con otro peso/reps sin pasar por el detalle.
    @ViewBuilder private func editor(_ target: EditTarget) -> some View {
        let i = target.index
        let existing: SetLog? = i < record.setLogs.count && i < record.completedSets ? record.setLogs[i] : nil
        let start = viewModel.proposedSet(for: exercise, record: record)
        let proposed = SetLog(reps: start.reps, weight: start.weight)
        SetQuickEditor(exercise: exercise, existing: existing, setNumber: i + 1,
                       suggested: proposed, p: p) { w, r, t, rpe in
            if var log = existing {
                log.weight = w; log.reps = r; log.type = t; log.rpe = rpe
                viewModel.updateSetLog(log, for: record.id, in: day)
            } else if i == record.completedSets {
                viewModel.completeSet(for: record.id, in: day, weight: w, reps: r, type: t, rpe: rpe)
            }
        }
    }

    /// Tocar la siguiente bolita marca la serie (y el modelo arranca el
    /// descanso); tocar la última marcada la deshace.
    private func tapSet(_ index: Int) {
        if index == record.completedSets {
            if exercise.segundos > 0 { timing = true; return }
            viewModel.completeSet(for: record.id, in: day)
        } else if index == record.completedSets - 1 {
            viewModel.undoLastSet(for: record.id, in: day)
        }
    }
}
