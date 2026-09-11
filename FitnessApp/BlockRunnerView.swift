//
//  BlockRunnerView.swift
//  ChamaFit
//
//  El reloj de un bloque AMRAP o EMOM dentro del modo entreno: cuenta
//  atrás grande, qué toca ahora y un botón para apuntar la vuelta (AMRAP)
//  o la serie del minuto (EMOM). Voz y vibración en cada cambio.
//

import SwiftUI
import Combine

struct BlockRunnerView: View {
    let day: WorkoutDay
    let group: Int

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("voiceCues", store: AppDefaults.store) private var voiceCues = true

    @StateObject private var engine = IntervalEngine()
    @State private var rounds = 0
    /// EMOM: minutos en los que ya se apuntó la serie.
    @State private var loggedMinutes: Set<Int> = []
    @State private var confirmStop = false

    private var p: Palette { themeManager.p }
    private var settings: BlockSettings { viewModel.block(day, group) }
    private var members: [(record: WorkoutExercise, exercise: Exercise)] {
        viewModel.blockMembers(day, group).compactMap { r in viewModel.getExercise(by: r.exerciseId).map { (r, $0) } }
    }

    var body: some View {
        ZStack {
            PulsoBackground(p: p)
            VStack(spacing: 0) {
                HStack {
                    CloseCircle(p: p) { if engine.running || rounds > 0 || !loggedMinutes.isEmpty { confirmStop = true } else { dismiss() } }
                    Spacer()
                    Text("\(settings.kind.label) · \(settings.minutes) min").font(.fig(15, .bold)).foregroundColor(p.ink)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20).padding(.top, 8)

                Spacer(minLength: 12)
                clock
                Spacer(minLength: 12)

                list.padding(.horizontal, 20)

                controls.padding(.horizontal, 20).padding(.bottom, 20).padding(.top, 16)
            }
        }
        .onAppear(perform: setup)
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { engine.tick(now: $0) }
        .confirmationDialog("¿Terminar el bloque?", isPresented: $confirmStop, titleVisibility: .visible) {
            Button("Terminar y guardar") { finish() }
            Button("Salir sin guardar", role: .destructive) { dismiss() }
            Button("Seguir", role: .cancel) {}
        } message: {
            Text((settings.kind == .amrap ? "Llevas \(rounds) \(rounds == 1 ? "vuelta" : "vueltas")." : String(localized: "Llevas \(loggedMinutes.count) de \(settings.minutes) minutos.")).loc)
        }
    }

    // MARK: - Piezas

    private var clock: some View {
        VStack(spacing: 6) {
            Text((engine.finished ? "¡Tiempo!" : engine.running ? (settings.kind == .emom ? "Minuto \(engine.index + 1) de \(settings.minutes)" : "Quedan") : "Preparado").loc)
                .font(.fig(15, .semibold)).foregroundColor(p.mute)
            Text((clockText(engine.remaining)).loc)
                .font(.bri(92)).em(-0.03, size: 92).monospacedDigit()
                .foregroundStyle(p.hgrad)
                .accessibilityIdentifier("block.clock")
            if settings.kind == .amrap {
                Text("\(rounds) \(rounds == 1 ? "vuelta" : "vueltas")")
                    .font(.bri(28)).foregroundColor(p.ink)
                    .accessibilityIdentifier("block.rounds")
            } else if let now = engine.current {
                Text((now.name).loc).font(.bri(28)).foregroundColor(p.ink).multilineTextAlignment(.center)
                    .accessibilityIdentifier("block.now")
                if let next = engine.next { Text("Después: \(next.name)").font(.fig(13, .medium)).foregroundColor(p.mute) }
            }
        }
        .padding(.horizontal, 20)
    }

    private var list: some View {
        VStack(spacing: 6) {
            ForEach(Array(members.enumerated()), id: \.element.record.id) { i, m in
                let isNow = settings.kind == .emom && engine.running && members.count > 0 && engine.index % members.count == i
                HStack {
                    Text((m.exercise.name).loc).font(.fig(14, isNow ? .bold : .semibold)).foregroundColor(isNow ? p.acc : p.ink)
                    Spacer()
                    Text(target(m.exercise, m.record)).font(.fig(13, .semibold)).foregroundColor(p.mute)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(isNow ? p.soft : p.card))
            }
        }
    }

    @ViewBuilder private var controls: some View {
        if engine.finished {
            PrimaryButton(title: "Guardar y seguir", icon: "checkmark", height: 64, fontSize: 18, p: p) { finish() }
                .accessibilityIdentifier("block.finish")
        } else if !engine.running {
            PrimaryButton(title: engine.elapsed() > 0 ? "Seguir" : "Empezar", icon: "play.fill", height: 64, fontSize: 18, p: p) {
                engine.start()
            }
            .accessibilityIdentifier("block.start")
        } else {
            HStack(spacing: 10) {
                SoftButton(title: "Pausa", icon: "pause.fill", height: 64, p: p) { engine.pause() }
                    .frame(width: 120)
                    .accessibilityIdentifier("block.pause")
                if settings.kind == .amrap {
                    PrimaryButton(title: "Vuelta hecha", icon: "checkmark", height: 64, fontSize: 18, p: p) {
                        viewModel.logRound(day, group)
                        rounds += 1
                    }
                    .accessibilityIdentifier("block.round")
                } else {
                    let minute = engine.index
                    PrimaryButton(title: loggedMinutes.contains(minute) ? "Apuntado" : "Hecho", icon: "checkmark",
                                  height: 64, fontSize: 18, enabled: !loggedMinutes.contains(minute), p: p) {
                        logEmom(minute)
                    }
                    .accessibilityIdentifier("block.done")
                }
            }
        }
    }

    // MARK: - Lógica

    private func setup() {
        engine.load(viewModel.blockPhases(day, group))
        engine.onPhaseChange = { phase, i in
            HapticManager.shared.goalAchieved()
            guard voiceCues else { return }
            if settings.kind == .emom { VoiceCoach.shared.say(String(localized: "Minuto \(i + 1): \(phase.name)"), interrupt: true) }
            else if i == 0 { VoiceCoach.shared.say(String(localized: "Empieza. \(settings.minutes) minutos"), interrupt: true) }
        }
        engine.onCountdown = { n in
            HapticManager.shared.selectionFeedback()
            if voiceCues && settings.kind == .amrap && engine.index == 0 && n == 3 && engine.remaining <= 3 { VoiceCoach.shared.say("Tres") }
        }
        engine.onFinish = {
            HapticManager.shared.success()
            if voiceCues { VoiceCoach.shared.say(settings.kind == .amrap ? "Tiempo. \(rounds) vueltas" : "Terminado", interrupt: true) }
        }
    }

    private func logEmom(_ minute: Int) {
        guard !members.isEmpty else { return }
        let m = members[minute % members.count]
        viewModel.logBlockSet(m.record.id, in: day)
        loggedMinutes.insert(minute)
    }

    private func finish() {
        engine.stop()
        if rounds > 0 || !loggedMinutes.isEmpty { viewModel.closeBlock(day, group) }
        dismiss()
    }

    private func target(_ ex: Exercise, _ rec: WorkoutExercise) -> String {
        let done = rec.setLogs.count
        let what = ex.segundos > 0 ? "\(ex.segundos) s" : String(localized: "\(ex.repetitions) reps")
        let w = ex.weight > 0 ? " · \(WorkoutViewModel.weightText(ex.weight, kind: ex.loadKind))" : ""
        return "\(what)\(w)\(done > 0 ? " · ✓\(done)" : "")"
    }

    private func clockText(_ s: Int) -> String { String(format: "%d:%02d", s / 60, s % 60) }
}
