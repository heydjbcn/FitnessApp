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
    /// Bloque AMRAP/EMOM abierto con su reloj.
    @State private var runningBlock: BlockTarget? = nil
    @State private var busy: BusyTarget? = nil
    @StateObject private var voice = VoiceInput()
    @State private var warmup: MobilityRoutine? = nil
    @State private var warmupDismissed = false
    /// Lo último que se oyó y qué se hizo con ello.
    @State private var heard: String? = nil
    @State private var showingDeadline = false
    struct BusyTarget: Identifiable { let recordId: UUID; let exerciseId: UUID; var id: UUID { recordId } }
    struct BlockTarget: Identifiable { let group: Int; var id: Int { group } }

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
        .sheet(item: $busy) { b in
            if let ex = viewModel.getExercise(by: b.exerciseId) {
                BusySheet(exercise: ex, recordId: b.recordId, day: day,
                          onLater: { if let r = viewModel.dailyWorkoutRecords[day]?.first(where: { $0.id == b.recordId }) { skip(r) } },
                          onSwapped: { advance() })
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
            }
        }
        .fullScreenCover(item: $warmup, onDismiss: { warmupDismissed = true }) { r in
            PhaseRunnerView(title: r.name, phases: r.phases, cues: { TechniqueGuide.entry(for: $0.name)?.cues }) { work, start, end in
                viewModel.logMobility(r, completed: work, start: start, end: end)
            }
            .environmentObject(viewModel)
            .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingDeadline) {
            TimeBudgetSheet(day: day)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .fullScreenCover(item: $runningBlock, onDismiss: { advance() }) { b in
            BlockRunnerView(day: day, group: b.group)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
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
                Text((viewModel.label(for: day) ?? viewModel.slotName(day)).loc)
                    .font(.fig(15, .bold)).foregroundColor(p.ink).lineLimit(1)
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let start = viewModel.sessionBounds(for: day)?.start ?? openedAt
                    Text("\(clock(ctx.date.timeIntervalSince(start))) · \(done)/\(total) series")
                        .font(.fig(12, .medium)).foregroundColor(p.mute).monospacedDigit()
                }
                if let d = viewModel.sessionDeadline {
                    let late = viewModel.isRunningLate(day)
                    Button { showingDeadline = true } label: {
                        Text((late ? "Vas tarde para las \(TimeBudgetSheet.time(d)) · recortar" : String(localized: "Límite \(TimeBudgetSheet.time(d))")).loc)
                            .font(.fig(11, .bold)).foregroundColor(late ? p.danger : p.acc)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("session.deadline")
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
                    if let w = viewModel.warmupLink(day), !warmupDismissed, viewModel.completedSets(for: day) == 0 {
                        HStack(spacing: 10) {
                            Image(systemName: "figure.flexibility").foregroundColor(p.acc)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Calentamiento: \(w.name)").font(.fig(14, .bold)).foregroundColor(p.ink)
                                Text("\(w.totalSeconds / 60) min, antes de empezar").font(.fig(12, .medium)).foregroundColor(p.mute)
                            }
                            Spacer()
                            Button("Empezar") { warmup = w }.font(.fig(13, .bold)).foregroundColor(p.acc)
                                .accessibilityIdentifier("session.warmup")
                            Button { warmupDismissed = true } label: { Image(systemName: "xmark") }
                                .font(.system(size: 12, weight: .bold)).foregroundColor(p.mute)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
                        .padding(.top, 12)
                    }
                    ExerciseIcon(exercise: ex, size: 76, radius: 24, gradient: true, p: p)
                        .padding(.top, 18)
                    if let g = rec.supersetGroup {
                        DayTag(text: "\(viewModel.block(day, g).kind.label) \(ExerciseDetailSheet.ssLetter(g))", icon: "arrow.triangle.2.circlepath",
                               filled: true, p: p)
                            .padding(.top, 12)
                    }
                    Text((ex.name).loc)
                        .font(.bri(30)).em(-0.03, size: 30)
                        .foregroundColor(p.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .accessibilityIdentifier("session.exercise")
                    Text("Serie \(rec.completedSets + 1) de \(rec.planned(ex))")
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
                        if rec.completedSets == 0 && ex.loadKind == .total {
                            WarmupCard(work: weight, p: p, bar: viewModel.activeEquipment.barWeightKg).padding(.top, 12)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
            }

            // Pie: saltar y el botón gordo.
            VStack(spacing: 10) {
                if let g = rec.supersetGroup, viewModel.block(day, g).kind.timed {
                    let b = viewModel.block(day, g)
                    Button { runningBlock = BlockTarget(group: g) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "timer").font(.system(size: 22, weight: .heavy))
                            Text("Empezar \(b.kind.label) de \(b.minutes) min").font(.bri(22))
                        }
                        .foregroundColor(p.onacc)
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                        .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(p.hgrad))
                        .shadow(color: p.glow1, radius: 18, y: 12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("session.block")
                } else if !timed || timedEnd == nil {
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
                if let heard = voice.listening ? (voice.transcript.isEmpty ? "Te escucho…" : voice.transcript) : heard {
                    Text((heard).loc)
                        .font(.fig(13, .semibold)).foregroundColor(voice.listening ? p.acc : p.mute)
                        .lineLimit(2).multilineTextAlignment(.center)
                        .accessibilityIdentifier("session.heard")
                }
                if let problem = voice.problem {
                    Text((problem).loc).font(.fig(12, .medium)).foregroundColor(p.danger).multilineTextAlignment(.center)
                }
                HStack(spacing: 14) {
                    Button { listen(rec, ex) } label: {
                        Image(systemName: voice.listening ? "waveform" : "mic.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(voice.listening ? p.onacc : p.ink)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(voice.listening ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
                            .symbolEffect(.variableColor.iterative, isActive: voice.listening)
                    }
                    .accessibilityIdentifier("session.mic")
                    .accessibilityLabel(voice.listening ? "Dejar de escuchar" : "Apuntar hablando")
                    if rec.completedSets > 0 {
                        Button { viewModel.undoLastSet(for: rec.id, in: day); load() } label: {
                            Label("Deshacer", systemImage: "arrow.uturn.backward").font(.fig(13, .semibold))
                        }
                        .accessibilityIdentifier("session.undo")
                    }
                    Spacer()
                    Button { busy = BusyTarget(recordId: rec.id, exerciseId: ex.id) } label: {
                        Label("Está ocupada", systemImage: "person.2.fill").font(.fig(13, .semibold))
                    }
                    .accessibilityIdentifier("session.busy")
                    Button { skip(rec) } label: {
                        Label("Saltar", systemImage: "forward.fill").font(.fig(13, .semibold))
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
            if ex.weight > 0 || weight > 0 || ex.loadKind == .bodyweight || ex.loadKind == .assisted {
                bigStepper(label: ex.loadKind.fieldLabel, value: WorkoutViewModel.kg(weight), id: "weight",
                           minus: { weight = Units.stepped(weight, by: -1) }, plus: { weight = Units.stepped(weight, by: 1) },
                           fine: [("−\(Units.plain(Units.fineStep))", { weight = Units.stepped(weight, by: -1, step: Units.fineStep) }),
                                  ("+\(Units.plain(Units.fineStep))", { weight = Units.stepped(weight, by: 1, step: Units.fineStep) })])
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
                Text((label).loc).font(.fig(12, .medium)).foregroundColor(p.mute)
                Text((value).loc).font(.bri(34)).foregroundColor(p.ink).monospacedDigit()
                    .accessibilityIdentifier("session.\(id)")
            }
            .frame(minWidth: 110, alignment: .leading)
            Spacer(minLength: 0)
            ForEach(fine.indices, id: \.self) { i in
                Button { fine[i].1(); HapticManager.shared.selectionFeedback() } label: {
                    Text((fine[i].0).loc).font(.fig(13, .bold)).foregroundColor(p.ink)
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

    // MARK: - Voz

    private func listen(_ rec: WorkoutExercise, _ ex: Exercise) {
        heard = nil
        voice.toggle { text in apply(VoiceCommandParser.parse(text, language: VoiceInput.language), text: text) }
    }

    /// Lo que se ha dicho, hecho. Lo que no se diga (peso, reps) se queda como estaba.
    func apply(_ command: VoiceCommand, text: String) {
        guard let cur = current else { return }
        let (rec, ex) = (cur.record, cur.exercise)
        switch command {
        case .set(let w, let unit, let r, let e):
            if let w {
                weight = unit == .lb ? w / Units.lbPerKg : unit == .kg ? w : Units.toKg(w)
            }
            if let r { reps = r }
            if let e { rpe = e }
            let what = [w.map { _ in WorkoutViewModel.kg(weight) }, r.map { "\($0) \(ex.segundos > 0 ? "s" : "reps")" }, e.map { String(localized: "RPE \($0)") }]
                .compactMap { $0 }.joined(separator: " × ")
            heard = "«\(text)» → \(what)"
            if ex.segundos > 0 {
                viewModel.completeSet(for: rec.id, in: day, weight: weight, reps: r ?? ex.segundos, rpe: rpe)
                advance()
            } else {
                done(rec, ex)
            }
            VoiceCoach.shared.say("Apuntado", interrupt: true)
        case .done:
            heard = String(localized: "«\(text)» → hecho")
            done(rec, ex)
        case .next:
            heard = String(localized: "«\(text)» → siguiente")
            skip(rec)
        case .undo:
            heard = String(localized: "«\(text)» → deshecho")
            if rec.completedSets > 0 { viewModel.undoLastSet(for: rec.id, in: day); load() }
        case .rest:
            heard = String(localized: "«\(text)» → descanso")
            if !viewModel.timerActive { viewModel.timerLabel = "Descanso"; viewModel.startTimer(duration: max(30, ex.restDuration)) }
        case .busy:
            heard = String(localized: "«\(text)» → está ocupada")
            busy = BusyTarget(recordId: rec.id, exerciseId: ex.id)
        case .unknown:
            heard = String(localized: "No te he entendido: «\(text)». Prueba «80 kilos por 8» o «hecho».")
            HapticManager.shared.warning()
        }
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
                        Text((next).loc).font(.fig(17, .bold)).foregroundColor(p.ink).multilineTextAlignment(.center)
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
                    Text((subtitle).loc).font(.fig(14, .medium)).foregroundColor(p.mute)
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
                                Text((r.name).loc).font(.fig(15, .semibold)).foregroundColor(p.ink)
                                Spacer()
                                Text((WorkoutViewModel.kg(r.weight)).loc).font(.bri(16)).foregroundColor(p.acc)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.soft))
                        }
                    }

                    if let prev = summary.previous {
                        UpperLabel(text: String(localized: "Frente a la última vez · \(WeeklyCalendarView.longDate(prev.date).lowercased())"), p: p)
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
        let name = summary.label.map { "\(summary.slotName) · \($0)" } ?? summary.slotName
        return String(localized: "\(name) · \(WeeklyCalendarView.longDate(Date()).lowercased())")
    }

    private func stat(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(p.acc)
            Text((value).loc).font(.bri(24)).foregroundColor(p.ink).lineLimit(1).minimumScaleFactor(0.7)
            Text((label).loc).font(.fig(12, .medium)).foregroundColor(p.mute)
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
            Text((text).loc).font(.bri(22)).foregroundColor(diff >= 0 ? p.acc : Pulso.danger(isDark: p.dark))
            Text((label).loc).font(.fig(12, .medium)).foregroundColor(p.mute)
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
                Text((summary.slotName).loc).font(.bri(46)).em(-0.03, size: 46).foregroundColor(p.ink)
                if let label = summary.label {
                    GradientText(text: label, font: .bri(38), p: p, tracking: -0.03 * 38).lineLimit(2)
                }
                VStack(alignment: .leading, spacing: 18) {
                    row(WorkoutViewModel.durationText(summary.duration), "de entreno")
                    row("\(summary.sets)", "series")
                    row(WorkoutViewModel.tonnageText(summary.volume), "levantados")
                    if let r = summary.records.first {
                        row("🏆 \(WorkoutViewModel.kg(r.weight))", String(localized: "récord en \(r.name)"))
                    }
                }
                .padding(.top, 36)
                Spacer()
                Text((WeeklyCalendarView.longDate(Date())).loc).font(.fig(14, .semibold)).foregroundColor(p.mute)
            }
            .padding(34)
        }
        .frame(width: 360, height: 640)
    }

    private func row(_ big: String, _ small: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text((big).loc).font(.bri(40)).foregroundStyle(p.hgrad)
            Text((small).loc).font(.fig(16, .semibold)).foregroundColor(p.ink)
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
                    UpperLabel(text: String(localized: "Serie \(setNumber) · por tiempo"), p: p)
                    Text((exercise.name).loc).font(.bri(20)).foregroundColor(p.ink)
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
