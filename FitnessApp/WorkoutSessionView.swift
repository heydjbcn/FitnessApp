//
//  WorkoutSessionView.swift
//  ChamaFit
//
//  Modo entreno: una pantalla para el gimnasio. El ejercicio que toca en
//  grande, la serie con el peso y las reps ya puestos, un botón «Hecho» que
//  se acierta sin mirar, el descanso a pantalla completa con lo siguiente y,
//  al terminar, el resumen de la sesión con su tarjeta para compartir.
//

import SwiftUI
import Combine

struct WorkoutSessionView: View {
    let day: WorkoutDay

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("keepScreenOn", store: AppDefaults.store) private var keepScreenOn = false

    @State private var skipped: Set<UUID> = []
    @State private var currentId: UUID? = nil
    @State private var weight: Double = 0
    @State private var reps: Int = 0
    @State private var rpe: Int? = nil
    @State private var openedAt = Date()
    @State private var summary: SessionSummary? = nil
    @State private var confirmFinish = false
    /// Cuenta atrás de un ejercicio por tiempo en curso.
    @State private var timedEnd: Date? = nil
    @State private var timedSpoken = -1

    private var p: Palette { themeManager.p }

    private var current: (record: WorkoutExercise, exercise: Exercise)? {
        guard let id = currentId,
              let rec = viewModel.dailyWorkoutRecords[day]?.first(where: { $0.id == id }),
              let ex = viewModel.getExercise(by: rec.exerciseId) else { return nil }
        return (rec, ex)
    }

    var body: some View {
        ZStack {
            PulsoBackground(p: p)
            if let summary {
                SessionSummaryView(summary: summary, p: p) { dismiss() }
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    topBar
                    if let cur = current {
                        exercisePanel(cur.record, cur.exercise)
                    } else {
                        finishedPanel
                    }
                }
                if viewModel.timerActive { RestOverlay(day: day, p: p).transition(.opacity) }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.timerActive)
        .animation(.easeInOut(duration: 0.25), value: summary == nil)
        .onAppear {
            openedAt = Date()
            UIApplication.shared.isIdleTimerDisabled = true
            advance()
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = keepScreenOn || AppDefaults.isTesting }
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { now in tickTimed(now) }
        .confirmationDialog("¿Terminar el entreno?", isPresented: $confirmFinish, titleVisibility: .visible) {
            Button("Terminar y ver resumen") { finish() }
        } message: {
            Text("Lo que has marcado queda guardado. Las series que falten se quedan sin hacer.")
        }
    }

    // MARK: - Barra de arriba

    private var topBar: some View {
        let done = viewModel.completedSets(for: day)
        let total = viewModel.totalSets(for: day)
        return HStack(spacing: 12) {
            CloseCircle(p: p) { dismiss() }
            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.label(for: day) ?? day.displayName)
                    .font(.fig(15, .bold)).foregroundColor(p.ink).lineLimit(1)
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let start = viewModel.sessionBounds(for: day)?.start ?? openedAt
                    Text("\(clock(ctx.date.timeIntervalSince(start))) · \(done)/\(total) series")
                        .font(.fig(12, .medium)).foregroundColor(p.mute).monospacedDigit()
                }
            }
            Spacer()
            Button { confirmFinish = true } label: {
                Text("Terminar").font(.fig(13, .bold)).foregroundColor(p.ink)
                    .padding(.horizontal, 14).frame(height: 36)
                    .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("session.finish")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Ejercicio actual

    private func exercisePanel(_ rec: WorkoutExercise, _ ex: Exercise) -> some View {
        let timed = ex.segundos > 0
        return VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ExerciseIcon(exercise: ex, size: 76, radius: 24, gradient: true, p: p)
                        .padding(.top, 18)
                    if let g = rec.supersetGroup {
                        DayTag(text: "Superserie \(ExerciseDetailSheet.ssLetter(g))", icon: "arrow.triangle.2.circlepath",
                               filled: true, p: p)
                            .padding(.top, 12)
                    }
                    Text(ex.name)
                        .font(.bri(30)).em(-0.03, size: 30)
                        .foregroundColor(p.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .accessibilityIdentifier("session.exercise")
                    Text("Serie \(rec.completedSets + 1) de \(ex.totalSets)")
                        .font(.fig(15, .semibold)).foregroundStyle(p.hgrad)
                        .padding(.top, 4)
                    if let note = ex.setupText {
                        Label(note, systemImage: "wrench.adjustable")
                            .font(.fig(13, .semibold)).foregroundColor(p.mute)
                            .padding(.top, 8)
                    }
                    if rec.completedSets == 0, let s = viewModel.suggestion(for: ex) {
                        SuggestionCard(suggestion: s, p: p).padding(.top, 14)
                    }

                    if timed {
                        timedPanel(ex).padding(.top, 20)
                    } else {
                        valuesPanel(ex).padding(.top, 20)
                        if rec.completedSets == 0 { WarmupCard(work: weight, p: p).padding(.top, 12) }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
            }

            // Pie: saltar y el botón gordo.
            VStack(spacing: 10) {
                if !timed || timedEnd == nil {
                    Button { done(rec, ex) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: timed ? "play.fill" : "checkmark").font(.system(size: 22, weight: .heavy))
                            Text(timed ? "Empezar \(ex.segundos) s" : "Hecho").font(.bri(24))
                        }
                        .foregroundColor(p.onacc)
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                        .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(p.hgrad))
                        .shadow(color: p.glow1, radius: 18, y: 12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("session.done")
                }
                HStack(spacing: 14) {
                    if rec.completedSets > 0 {
                        Button { viewModel.undoLastSet(for: rec.id, in: day); load() } label: {
                            Label("Deshacer", systemImage: "arrow.uturn.backward").font(.fig(13, .semibold))
                        }
                        .accessibilityIdentifier("session.undo")
                    }
                    Spacer()
                    Button { skip(rec) } label: {
                        Label("Saltar ejercicio", systemImage: "forward.fill").font(.fig(13, .semibold))
                    }
                    .accessibilityIdentifier("session.skip")
                }
                .foregroundColor(p.mute)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
    }

    private func valuesPanel(_ ex: Exercise) -> some View {
        VStack(spacing: 10) {
            if ex.weight > 0 || weight > 0 {
                bigStepper(label: "Peso", value: WorkoutViewModel.kg(weight), id: "weight",
                           minus: { weight = max(0, weight - 2.5) }, plus: { weight += 2.5 },
                           fine: [("−1", { weight = max(0, weight - 1) }), ("+1", { weight += 1 })])
            }
            bigStepper(label: "Repeticiones", value: "\(reps)", id: "reps",
                       minus: { reps = max(0, reps - 1) }, plus: { reps += 1 }, fine: [])
            HStack(spacing: 6) {
                Text("RPE").font(.fig(11, .bold)).tracking(0.5).foregroundColor(p.mute).frame(width: 34)
                ForEach(6...10, id: \.self) { v in
                    let on = rpe == v
                    Button { rpe = on ? nil : v; HapticManager.shared.selectionFeedback() } label: {
                        Text("\(v)").font(.bri(15))
                            .foregroundColor(on ? p.onacc : p.ink)
                            .frame(maxWidth: .infinity).frame(height: 38)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(on ? AnyShapeStyle(p.grad) : AnyShapeStyle(p.soft)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func bigStepper(label: String, value: String, id: String, minus: @escaping () -> Void,
                            plus: @escaping () -> Void, fine: [(String, () -> Void)]) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.fig(12, .medium)).foregroundColor(p.mute)
                Text(value).font(.bri(34)).foregroundColor(p.ink).monospacedDigit()
                    .accessibilityIdentifier("session.\(id)")
            }
            .frame(minWidth: 110, alignment: .leading)
            Spacer(minLength: 0)
            ForEach(fine.indices, id: \.self) { i in
                Button { fine[i].1(); HapticManager.shared.selectionFeedback() } label: {
                    Text(fine[i].0).font(.fig(13, .bold)).foregroundColor(p.ink)
                        .frame(width: 42, height: 50)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.card))
                }
                .buttonStyle(.plain)
            }
            roundButton("minus", minus).accessibilityIdentifier("session.\(id).minus")
            roundButton("plus", plus).accessibilityIdentifier("session.\(id).plus")
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(p.soft))
    }

    private func roundButton(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button { action(); HapticManager.shared.selectionFeedback() } label: {
            Image(systemName: symbol).font(.system(size: 18, weight: .bold)).foregroundColor(p.onacc)
                .frame(width: 50, height: 50).background(Circle().fill(p.grad))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ejercicio por tiempo

    private func timedPanel(_ ex: Exercise) -> some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { ctx in
            let total = Double(ex.segundos)
            let left = timedEnd.map { max(0, $0.timeIntervalSince(ctx.date)) } ?? total
            ZStack {
                Circle().stroke(p.soft, lineWidth: 14)
                Circle().trim(from: 0, to: total > 0 ? left / total : 0)
                    .stroke(p.hgrad, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(Int(ceil(left)))").font(.bri(64)).foregroundColor(p.ink).monospacedDigit()
                    Text(timedEnd == nil ? "segundos" : "¡aguanta!").font(.fig(14, .semibold)).foregroundColor(p.mute)
                }
            }
            .frame(width: 220, height: 220)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("session.timed")
        }
    }

    private func tickTimed(_ now: Date) {
        guard let end = timedEnd, let cur = current else { return }
        let left = Int(ceil(end.timeIntervalSince(now)))
        if left != timedSpoken {
            timedSpoken = left
            switch left {
            case 10: VoiceCoach.shared.say("Quedan diez segundos")
            case 3, 2, 1: VoiceCoach.shared.say(["uno", "dos", "tres"][left - 1], interrupt: true)
            default: break
            }
        }
        if left <= 0 {
            timedEnd = nil
            VoiceCoach.shared.say("¡Hecho!", interrupt: true)
            viewModel.completeSet(for: cur.record.id, in: day, weight: weight, reps: cur.exercise.segundos)
            advance()
        }
    }

    // MARK: - Terminado

    private var finishedPanel: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checkmark.seal.fill").font(.system(size: 64)).foregroundStyle(p.hgrad)
            Text("¡Sesión completada!").font(.bri(28)).foregroundColor(p.ink)
            Text("Has hecho todas las series del día.").font(.fig(15, .medium)).foregroundColor(p.mute)
            PrimaryButton(title: "Ver resumen", icon: "chart.bar.fill", height: 56, p: p) { finish() }
                .padding(.horizontal, 30).padding(.top, 10)
                .accessibilityIdentifier("session.summary")
            Spacer()
        }
    }

    // MARK: - Acciones

    private func done(_ rec: WorkoutExercise, _ ex: Exercise) {
        if ex.segundos > 0 {
            timedEnd = Date().addingTimeInterval(TimeInterval(ex.segundos))
            timedSpoken = -1
            VoiceCoach.shared.say("¡Ya!", interrupt: true)
            HapticManager.shared.buttonTapped()
            return
        }
        viewModel.completeSet(for: rec.id, in: day, weight: weight, reps: reps, rpe: rpe)
        advance()
    }

    private func skip(_ rec: WorkoutExercise) {
        skipped.insert(rec.id)
        HapticManager.shared.selectionFeedback()
        advance()
    }

    /// Pasa al ejercicio que toque y carga su serie propuesta.
    private func advance() {
        rpe = nil
        if viewModel.nextRecord(in: day, skipping: skipped) == nil { skipped = [] }
        currentId = viewModel.nextRecord(in: day, skipping: skipped)?.id
        load()
    }

    private func load() {
        guard let cur = current else { return }
        let s = viewModel.proposedSet(for: cur.exercise, record: cur.record)
        weight = s.weight
        reps = s.reps
    }

    private func finish() {
        timedEnd = nil
        viewModel.stopTimer(silent: true)
        let s = viewModel.sessionSummary(for: day, endedAt: Date())
        viewModel.sessionFinished(s)
        summary = s
        HapticManager.shared.success()
    }

    private func clock(_ t: TimeInterval) -> String {
        let s = max(0, Int(t))
        return s >= 3600 ? String(format: "%d:%02d:%02d", s / 3600, s / 60 % 60, s % 60)
                         : String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - Descanso a pantalla completa

private struct RestOverlay: View {
    let day: WorkoutDay
    let p: Palette
    @EnvironmentObject var viewModel: WorkoutViewModel

    var body: some View {
        let total = max(1, viewModel.currentTimerDuration)
        let left = viewModel.timeRemaining
        ZStack {
            p.bg.opacity(0.97).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                UpperLabel(text: "Descanso", p: p)
                ZStack {
                    Circle().stroke(p.soft, lineWidth: 16)
                    Circle().trim(from: 0, to: Double(left) / Double(total))
                        .stroke(p.hgrad, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: left)
                    Text(String(format: "%d:%02d", left / 60, left % 60))
                        .font(.bri(64)).foregroundColor(p.ink).monospacedDigit()
                        .contentTransition(.numericText())
                        .accessibilityIdentifier("rest.clock")
                }
                .frame(width: 250, height: 250)
                .padding(.top, 18)

                if let next = viewModel.nextUpText(in: day) {
                    VStack(spacing: 4) {
                        UpperLabel(text: "Siguiente", p: p)
                        Text(next).font(.fig(17, .bold)).foregroundColor(p.ink).multilineTextAlignment(.center)
                    }
                    .padding(.top, 26).padding(.horizontal, 30)
                }
                Spacer()
                HStack(spacing: 12) {
                    SoftButton(title: "+30 s", height: 60, fontSize: 17, p: p) { viewModel.extendTimer(by: 30) }
                        .accessibilityIdentifier("rest.extend")
                    PrimaryButton(title: "Saltar descanso", height: 60, fontSize: 17, p: p) {
                        HapticManager.shared.timerStopped()
                        viewModel.stopTimer()
                    }
                    .accessibilityIdentifier("rest.skip")
                }
                .padding(.horizontal, 22).padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Resumen

struct SessionSummaryView: View {
    let summary: SessionSummary
    let p: Palette
    let onClose: () -> Void

    @State private var shareImage: Image? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Image(systemName: "trophy.fill").font(.system(size: 40)).foregroundStyle(p.hgrad)
                        .frame(maxWidth: .infinity).padding(.top, 30)
                    Text("¡Buen entreno!").font(.bri(32)).em(-0.03, size: 32).foregroundColor(p.ink)
                        .frame(maxWidth: .infinity).padding(.top, 10)
                    Text(subtitle).font(.fig(14, .medium)).foregroundColor(p.mute)
                        .frame(maxWidth: .infinity).padding(.top, 4)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        stat("Duración", WorkoutViewModel.durationText(summary.duration), "clock.fill")
                        stat("Series", "\(summary.sets)/\(summary.totalSets)", "checkmark.circle.fill")
                        stat("Tonelaje", WorkoutViewModel.tonnageText(summary.volume), "scalemass.fill")
                        stat("Ejercicios", "\(summary.exercisesDone)", "dumbbell.fill")
                    }
                    .padding(.top, 22)

                    if !summary.records.isEmpty {
                        UpperLabel(text: "Récords de hoy", p: p).padding(.top, 22).padding(.bottom, 8)
                        ForEach(summary.records, id: \.name) { r in
                            HStack {
                                Image(systemName: "trophy.fill").foregroundStyle(p.hgrad)
                                Text(r.name).font(.fig(15, .semibold)).foregroundColor(p.ink)
                                Spacer()
                                Text(WorkoutViewModel.kg(r.weight)).font(.bri(16)).foregroundColor(p.acc)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.soft))
                        }
                    }

                    if let prev = summary.previous {
                        UpperLabel(text: "Frente a la última vez · \(WeeklyCalendarView.longDate(prev.date).lowercased())", p: p)
                            .padding(.top, 22).padding(.bottom, 8)
                        HStack(spacing: 10) {
                            delta("Tonelaje", now: summary.volume, before: prev.volume, percent: true)
                            delta("Series", now: Double(summary.sets), before: Double(prev.sets), percent: false)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 20)
            }
            HStack(spacing: 10) {
                if let shareImage {
                    ShareLink(item: shareImage, preview: SharePreview("Mi entreno en ChamaFit", image: shareImage)) {
                        Label("Compartir", systemImage: "square.and.arrow.up").font(.fig(15, .bold))
                            .foregroundColor(p.ink).frame(maxWidth: .infinity).frame(height: 54)
                            .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
                    }
                    .accessibilityIdentifier("summary.share")
                }
                PrimaryButton(title: "Listo", height: 54, p: p, action: onClose)
                    .accessibilityIdentifier("summary.close")
            }
            .padding(.horizontal, 22).padding(.bottom, 12)
        }
        .onAppear(perform: render)
    }

    private var subtitle: String {
        let name = summary.label.map { "\(summary.day.displayName) · \($0)" } ?? summary.day.displayName
        return "\(name) · \(WeeklyCalendarView.longDate(Date()).lowercased())"
    }

    private func stat(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(p.acc)
            Text(value).font(.bri(24)).foregroundColor(p.ink).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.fig(12, .medium)).foregroundColor(p.mute)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .pulsoCard(p, radius: 18)
    }

    private func delta(_ label: String, now: Double, before: Double, percent: Bool) -> some View {
        let diff = now - before
        let text: String
        if percent {
            text = before > 0 ? "\(diff >= 0 ? "+" : "")\(Int((diff / before * 100).rounded())) %" : "—"
        } else {
            text = "\(diff >= 0 ? "+" : "")\(Int(diff))"
        }
        return VStack(alignment: .leading, spacing: 4) {
            Text(text).font(.bri(22)).foregroundColor(diff >= 0 ? p.acc : Pulso.danger(isDark: p.dark))
            Text(label).font(.fig(12, .medium)).foregroundColor(p.mute)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .pulsoCard(p, radius: 18)
    }

    @MainActor private func render() {
        let renderer = ImageRenderer(content: SessionShareCard(summary: summary, p: p))
        renderer.scale = 3
        if let ui = renderer.uiImage { shareImage = Image(uiImage: ui) }
    }
}

/// La tarjeta de historias: 360 × 640 puntos (1080 × 1920 al exportar).
struct SessionShareCard: View {
    let summary: SessionSummary
    let p: Palette

    var body: some View {
        ZStack {
            p.bg
            Circle().fill(p.glow1).frame(width: 420).blur(radius: 90).offset(x: -120, y: -250)
            Circle().fill(p.glow2).frame(width: 360).blur(radius: 100).offset(x: 150, y: 200)
            VStack(alignment: .leading, spacing: 0) {
                Text("CHAMAFIT").font(.fig(13, .bold)).tracking(2).foregroundColor(p.mute)
                Spacer()
                Text(summary.day.displayName).font(.bri(46)).em(-0.03, size: 46).foregroundColor(p.ink)
                if let label = summary.label {
                    GradientText(text: label, font: .bri(38), p: p, tracking: -0.03 * 38).lineLimit(2)
                }
                VStack(alignment: .leading, spacing: 18) {
                    row(WorkoutViewModel.durationText(summary.duration), "de entreno")
                    row("\(summary.sets)", "series")
                    row(WorkoutViewModel.tonnageText(summary.volume), "levantados")
                    if let r = summary.records.first {
                        row("🏆 \(WorkoutViewModel.kg(r.weight))", "récord en \(r.name)")
                    }
                }
                .padding(.top, 36)
                Spacer()
                Text(WeeklyCalendarView.longDate(Date())).font(.fig(14, .semibold)).foregroundColor(p.mute)
            }
            .padding(34)
        }
        .frame(width: 360, height: 640)
    }

    private func row(_ big: String, _ small: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(big).font(.bri(40)).foregroundStyle(p.hgrad)
            Text(small).font(.fig(16, .semibold)).foregroundColor(p.ink)
        }
    }
}

// MARK: - Serie por tiempo desde Inicio

/// La bolita de un ejercicio por tiempo (plancha 45 s): cuenta atrás y, al
/// llegar a cero, marca la serie (y el modelo arranca el descanso).
struct TimedSetSheet: View {
    let exercise: Exercise
    let setNumber: Int
    let p: Palette
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var end: Date? = nil
    @State private var spoken = -1

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "Serie \(setNumber) · por tiempo", p: p)
                    Text(exercise.name).font(.bri(20)).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)

            TimelineView(.periodic(from: .now, by: 0.25)) { ctx in
                let total = Double(exercise.segundos)
                let left = end.map { max(0, $0.timeIntervalSince(ctx.date)) } ?? total
                ZStack {
                    Circle().stroke(p.soft, lineWidth: 12)
                    Circle().trim(from: 0, to: total > 0 ? left / total : 0)
                        .stroke(p.hgrad, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(ceil(left)))").font(.bri(56)).foregroundColor(p.ink).monospacedDigit()
                }
                .frame(width: 190, height: 190)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .onChange(of: Int(ceil(left))) { _, sec in tick(sec) }
            }
        } footer: {
            SheetFooter(p: p) {
                if end == nil {
                    PrimaryButton(title: "Empezar", icon: "play.fill", height: 50, p: p) {
                        end = Date().addingTimeInterval(TimeInterval(exercise.segundos))
                        VoiceCoach.shared.say("¡Ya!", interrupt: true)
                    }
                    .accessibilityIdentifier("timed.start")
                } else {
                    SoftButton(title: "Marcar ya", height: 50, p: p) { finish() }
                        .accessibilityIdentifier("timed.finish")
                }
            }
        }
        .presentationDetents([.height(420)])
    }

    private func tick(_ sec: Int) {
        guard end != nil, sec != spoken else { return }
        spoken = sec
        switch sec {
        case 10: VoiceCoach.shared.say("Quedan diez segundos")
        case 1...3: VoiceCoach.shared.say(["uno", "dos", "tres"][sec - 1], interrupt: true)
        case ...0: finish()
        default: break
        }
    }

    private func finish() {
        end = nil
        VoiceCoach.shared.say("¡Hecho!", interrupt: true)
        onDone()
        dismiss()
    }
}
