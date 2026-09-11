//
//  IntervalViews.swift
//  ChamaFit
//
//  Intervalos HIIT y movilidad: elegir, ajustar y el reloj a pantalla
//  completa con colores por fase, voz, vibración y Live Activity.
//

import SwiftUI
import Combine

// MARK: - Reloj a pantalla completa

struct PhaseRunnerView: View {
    let title: String
    let phases: [IntervalEngine.Phase]
    /// Técnica de la fase (movilidad): claves para leer mientras.
    var cues: (IntervalEngine.Phase) -> [String]? = { _ in nil }
    /// Al acabar (o terminar antes): segundos de cada fase de trabajo hecha, inicio y fin.
    let onFinish: (_ work: [Int], _ start: Date, _ end: Date) -> Void

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("voiceCues", store: AppDefaults.store) private var voiceCues = true
    @StateObject private var engine = IntervalEngine()
    @State private var startedAt: Date? = nil
    @State private var doneWork: [Int] = []
    @State private var confirmStop = false
    @State private var saved = false

    private var p: Palette { themeManager.p }

    private func tint(_ k: IntervalEngine.Phase.Kind) -> Color {
        switch k {
        case .work: return p.acc
        case .rest: return Pulso.ok(isDark: p.dark)
        case .warmup, .cooldown: return Color(red: 0.35, green: 0.6, blue: 1)
        }
    }

    var body: some View {
        let phase = engine.current
        ZStack {
            PulsoBackground(p: p)
            (phase.map { tint($0.kind) } ?? p.acc).opacity(engine.running ? 0.22 : 0.08).ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: engine.index)
            VStack(spacing: 0) {
                HStack {
                    CloseCircle(p: p) { if startedAt != nil && !engine.finished { confirmStop = true } else { close() } }
                    Spacer()
                    Text((title).loc).font(.fig(15, .bold)).foregroundColor(p.ink)
                    Spacer()
                    Text("\(min(engine.index + 1, max(1, phases.count)))/\(phases.count)").font(.fig(13, .bold)).foregroundColor(p.mute)
                        .frame(width: 44)
                }
                .padding(.horizontal, 20).padding(.top, 8)

                Spacer()
                VStack(spacing: 10) {
                    Text(engine.finished ? "¡Terminado!" : (phase?.name ?? ""))
                        .font(.bri(32)).em(-0.02, size: 32).foregroundColor(p.ink)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("phase.name")
                    Text(String(format: "%d:%02d", engine.remaining / 60, engine.remaining % 60))
                        .font(.bri(110)).monospacedDigit()
                        .foregroundColor(phase.map { tint($0.kind) } ?? p.acc)
                        .accessibilityIdentifier("phase.clock")
                    if let next = engine.next, !engine.finished {
                        Text("Después: \(next.name) · \(next.seconds) s").font(.fig(14, .semibold)).foregroundColor(p.mute)
                    }
                    if let phase, let c = cues(phase), !c.isEmpty, phase.kind == .work {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(c.prefix(3).enumerated()), id: \.offset) { _, cue in
                                Label(cue.loc, systemImage: "checkmark").font(.fig(13, .medium)).foregroundColor(p.ink)
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.card))
                        .padding(.horizontal, 24).padding(.top, 8)
                    }
                }
                Spacer()

                GeometryReader { geo in
                    let total = max(1, engine.totalSeconds)
                    let done = Double(engine.elapsed())
                    ZStack(alignment: .leading) {
                        Capsule().fill(p.soft)
                        Capsule().fill(p.hgrad).frame(width: geo.size.width * CGFloat(min(1, done / Double(total))))
                    }
                }
                .frame(height: 8).padding(.horizontal, 24)

                controls.padding(.horizontal, 20).padding(.vertical, 20)
            }
        }
        .onAppear(perform: setup)
        .onDisappear { viewModel.endPhaseActivity() }
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { engine.tick(now: $0) }
        .confirmationDialog("¿Terminar ya?", isPresented: $confirmStop, titleVisibility: .visible) {
            Button("Terminar y guardar lo hecho") { save(); close() }
            Button("Salir sin guardar", role: .destructive) { close() }
            Button("Seguir", role: .cancel) {}
        }
    }

    @ViewBuilder private var controls: some View {
        if engine.finished {
            PrimaryButton(title: "Guardar", icon: "checkmark", height: 64, fontSize: 18, p: p) { save(); close() }
                .accessibilityIdentifier("phase.save")
        } else if !engine.running {
            PrimaryButton(title: startedAt == nil ? "Empezar" : "Seguir", icon: "play.fill", height: 64, fontSize: 18, p: p) {
                if startedAt == nil { startedAt = Date() }
                engine.start()
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .accessibilityIdentifier("phase.start")
        } else {
            HStack(spacing: 10) {
                SoftButton(title: "Pausa", icon: "pause.fill", height: 64, p: p) { engine.pause() }
                    .accessibilityIdentifier("phase.pause")
                SoftButton(title: "Saltar", icon: "forward.fill", height: 64, p: p) { engine.skip() }
                    .accessibilityIdentifier("phase.skip")
            }
        }
    }

    private func setup() {
        engine.load(phases)
        engine.onPhaseChange = { phase, i in
            // La fase anterior, si era de trabajo, cuenta como hecha.
            if i > 0, phases.indices.contains(i - 1), phases[i - 1].kind == .work { doneWork.append(phases[i - 1].seconds) }
            HapticManager.shared.goalAchieved()
            if voiceCues {
                let text = phase.kind == .work ? phase.name == "Trabajo" ? "¡Ya!" : phase.name
                         : phase.kind == .rest ? "Descansa" : phase.name
                VoiceCoach.shared.say(text, interrupt: true)
            }
            viewModel.showPhaseActivity(end: Date().addingTimeInterval(TimeInterval(phase.seconds)), label: phase.name, session: title)
        }
        engine.onCountdown = { n in
            HapticManager.shared.selectionFeedback()
            if voiceCues && n <= 3 { VoiceCoach.shared.say("\(n)") }
        }
        engine.onFinish = {
            if let last = phases.last, last.kind == .work { doneWork.append(last.seconds) }
            HapticManager.shared.success()
            if voiceCues { VoiceCoach.shared.say("Terminado. ¡Buen trabajo!", interrupt: true) }
            viewModel.endPhaseActivity()
        }
    }

    private func save() {
        guard !saved, let start = startedAt else { return }
        saved = true
        var work = doneWork
        // Terminado antes de tiempo: la fase de trabajo en curso cuenta lo hecho.
        if !engine.finished, let cur = engine.current, cur.kind == .work {
            let done = cur.seconds - engine.remaining
            if done >= 5 { work.append(done) }
        }
        onFinish(work, start, Date())
    }

    private func close() {
        engine.stop()
        UIApplication.shared.isIdleTimerDisabled = AppDefaults.isTesting
        viewModel.endPhaseActivity()
        dismiss()
    }
}

// MARK: - Elegir intervalos

struct IntervalsSheet: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var plan = IntervalPlan.presets[0]
    @State private var running: IntervalPlan? = nil

    private var p: Palette { themeManager.p }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "HIIT", p: p)
                    Text("Intervalos").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    FlowLayout(spacing: 6) {
                        ForEach(IntervalPlan.presets + viewModel.savedIntervalPlans) { pr in
                            TagChip(text: pr.name, selected: plan.name == pr.name && plan.work == pr.work, p: p) { plan = pr }
                                .accessibilityIdentifier("hiit.preset.\(pr.name)")
                        }
                    }
                    row("Calentamiento", $plan.warmup, step: 30, range: 0...900)
                    row("Trabajo", $plan.work, step: 5, range: 5...600)
                    row("Descanso", $plan.rest, step: 5, range: 0...600)
                    intRow("Vueltas", $plan.rounds, range: 1...50)
                    intRow("Bloques", $plan.blocks, range: 1...10)
                    if plan.blocks > 1 { row("Descanso entre bloques", $plan.blockRest, step: 15, range: 0...600) }
                    row("Vuelta a la calma", $plan.cooldown, step: 30, range: 0...900)
                    Text("Total: \(plan.totalSeconds / 60) min \(plan.totalSeconds % 60) s · \(plan.workSeconds / 60) min de trabajo")
                        .font(.fig(14, .semibold)).foregroundColor(p.acc)
                        .accessibilityIdentifier("hiit.total")
                    SoftButton(title: String(localized: "Guardar como «\(plan.name)»"), icon: "square.and.arrow.down", height: 40, fontSize: 13, p: p) {
                        var mine = viewModel.savedIntervalPlans.filter { $0.name != plan.name }
                        var copy = plan; copy.id = UUID()
                        mine.append(copy)
                        viewModel.savedIntervalPlans = mine
                        HapticManager.shared.success()
                    }
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        } footer: {
            SheetFooter(p: p) {
                PrimaryButton(title: "Empezar", icon: "play.fill", height: 50, p: p) { running = plan }
                    .accessibilityIdentifier("hiit.go")
            }
        }
        .fullScreenCover(item: $running) { pl in
            PhaseRunnerView(title: pl.name, phases: pl.phases) { work, start, end in
                viewModel.logHIIT(pl, completedWork: work, start: start, end: end)
            }
            .environmentObject(viewModel)
            .environmentObject(themeManager)
        }
    }

    private func row(_ label: String, _ value: Binding<Int>, step: Int, range: ClosedRange<Int>) -> some View {
        HStack {
            Text((label).loc).font(.fig(14, .semibold)).foregroundColor(p.ink)
            Spacer()
            Stepper(WorkoutViewModel.restText(value.wrappedValue), value: value, in: range, step: step)
                .font(.fig(14, .semibold)).fixedSize()
        }
    }

    private func intRow(_ label: String, _ value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text((label).loc).font(.fig(14, .semibold)).foregroundColor(p.ink)
            Spacer()
            Stepper("\(value.wrappedValue)", value: value, in: range).font(.fig(14, .semibold)).fixedSize()
                .accessibilityIdentifier("hiit.\(label)")
        }
    }
}

// MARK: - Movilidad

struct MobilitySheet: View {
    /// Si se abre desde una sesión: se puede enganchar como su calentamiento.
    var linkDay: WorkoutDay? = nil

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var running: MobilityRoutine? = nil
    @State private var editing: MobilityRoutine? = nil

    private var p: Palette { themeManager.p }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "Por tiempo, con técnica", p: p)
                    Text("Movilidad y calentamiento").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.mobilityRoutines) { r in card(r) }
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        } footer: {
            SheetFooter(p: p) {
                SoftButton(title: "Crear la mía", icon: "plus", height: 50, p: p) {
                    editing = MobilityRoutine(name: "Mi movilidad", items: [.init(name: "Gato-camello", seconds: 45)])
                }
                .accessibilityIdentifier("mobility.new")
            }
        }
        .fullScreenCover(item: $running) { r in
            PhaseRunnerView(title: r.name, phases: r.phases, cues: { TechniqueGuide.entry(for: $0.name)?.cues }) { work, start, end in
                viewModel.logMobility(r, completed: work, start: start, end: end)
            }
            .environmentObject(viewModel)
            .environmentObject(themeManager)
        }
        .sheet(item: $editing) { r in
            MobilityEditor(routine: r).environmentObject(viewModel).environmentObject(themeManager)
        }
    }

    private func card(_ r: MobilityRoutine) -> some View {
        let linked = linkDay.flatMap { viewModel.warmupLink($0) }?.id == r.id
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text((r.name).loc).font(.fig(16, .bold)).foregroundColor(p.ink)
                Spacer()
                Text("\(r.totalSeconds / 60) min").font(.fig(13, .semibold)).foregroundColor(p.acc)
            }
            Text(r.items.map(\.name).joined(separator: " · ")).font(.fig(12, .medium)).foregroundColor(p.mute)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                PrimaryButton(title: "Empezar", icon: "play.fill", height: 38, fontSize: 13, p: p) { running = r }
                    .accessibilityIdentifier("mobility.start.\(r.name)")
                if let d = linkDay {
                    SoftButton(title: linked ? "Calienta antes ✓" : "Calentar antes de esta sesión", height: 38, fontSize: 12, p: p) {
                        viewModel.setWarmupLink(linked ? nil : r, for: d)
                    }
                    .accessibilityIdentifier("mobility.link.\(r.name)")
                }
                if !MobilityRoutine.presets.contains(where: { $0.id == r.id }) {
                    Button { editing = r } label: { Image(systemName: "pencil") }
                        .foregroundColor(p.mute).frame(width: 38, height: 38)
                }
            }
        }
        .padding(14)
        .pulsoCard(p, radius: 20)
    }
}

struct MobilityEditor: View {
    @State var routine: MobilityRoutine
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    private var p: Palette { themeManager.p }
    private var options: [String] {
        ExerciseCatalog.all.filter { $0.muscleGroup == "Movilidad" || $0.muscleGroup == "Core" || $0.reps == 0 }.map(\.name)
    }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                Text("Tu movilidad").font(.bri(22)).foregroundColor(p.ink)
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    PulsoField(placeholder: "Nombre", text: $routine.name, p: p)
                    ForEach(Array(routine.items.enumerated()), id: \.offset) { i, it in
                        HStack {
                            Text((it.name).loc).font(.fig(14, .semibold)).foregroundColor(p.ink)
                            Spacer()
                            Stepper("\(it.seconds) s", value: $routine.items[i].seconds, in: 10...300, step: 5).fixedSize()
                            Button { routine.items.remove(at: i) } label: { Image(systemName: "trash") }.foregroundColor(p.danger)
                        }
                    }
                    Menu {
                        ForEach(options, id: \.self) { n in Button(n.loc) { routine.items.append(.init(name: n, seconds: 45)) } }
                    } label: {
                        Label("Añadir ejercicio", systemImage: "plus").font(.fig(14, .semibold)).foregroundColor(p.acc)
                    }
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        } footer: {
            SheetFooter(p: p) {
                PrimaryButton(title: "Guardar", icon: "checkmark", height: 50, enabled: !routine.items.isEmpty, p: p) {
                    var all = viewModel.mobilityRoutines.filter { !MobilityRoutine.presets.contains($0) && $0.id != routine.id }
                    all.append(routine)
                    viewModel.mobilityRoutines = all
                    dismiss()
                }
            }
        }
    }
}
