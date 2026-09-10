//
//  CoachAIView.swift
//  ChamaFit
//
//  Coach IA en estilo «Pulso»: pregunta sobre tu rutina, técnica o progresión
//  a Claude, con tu rutina y tus últimas marcas como contexto.
//

import SwiftUI

struct CoachAIView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var coach = AICoachManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var prompt = ""
    @State private var thread: [(question: String, answer: String)] = []
    @State private var loading = false
    @State private var errorMsg: String?
    @State private var keyDraft = ""
    @State private var showingKey = false
    @FocusState private var focused: Bool

    private var p: Palette { themeManager.p }

    private let suggestions = [
        "Ajusta mi rutina del lunes para ganar fuerza",
        "¿Estoy entrenando equilibrado por grupos musculares?",
        "Dame un calentamiento para piernas",
        "¿Cómo progreso de peso sin estancarme?"
    ]

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "Claude", p: p)
                    Text("Coach IA").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                if coach.hasKey {
                    Button { showingKey = true } label: {
                        Image(systemName: "key.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(p.mute)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(p.soft))
                            .overlay(Circle().strokeBorder(p.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)

            if coach.hasKey && !showingKey { chat } else { keyEntry }
        }
    }

    // MARK: - API key

    private var keyEntry: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                IconTile(symbol: "sparkles", size: 56, radius: 18, gradient: true, glow: true, p: p)
                Text("Activa el Coach IA")
                    .font(.bri(20)).em(-0.02, size: 20).foregroundColor(p.ink)
                    .padding(.top, 16)
                Text("Pega tu API key de Anthropic. Es de pago por uso y se guarda solo en este iPhone.")
                    .font(.fig(13, .medium)).lineSpacing(3).foregroundColor(p.mute)
                    .padding(.top, 6)
                UpperLabel(text: "API key", p: p).padding(.top, 18).padding(.bottom, 6)
                SecureField("", text: $keyDraft, prompt: Text("sk-ant-…").foregroundColor(p.mute.opacity(0.8)))
                    .font(.fig(15, .semibold))
                    .foregroundColor(p.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(p.line, lineWidth: 1))
                PrimaryButton(title: "Guardar y activar", height: 50,
                              enabled: !keyDraft.trimmingCharacters(in: .whitespaces).isEmpty, p: p) {
                    coach.apiKey = keyDraft.trimmingCharacters(in: .whitespaces)
                    showingKey = false
                    HapticManager.shared.success()
                }
                .padding(.top, 14)
                if coach.hasKey {
                    SoftButton(title: "Quitar la key", height: 44, color: p.danger, filled: false, p: p) {
                        coach.apiKey = ""
                        keyDraft = ""
                        showingKey = false
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 30)
        }
        .onAppear { keyDraft = coach.apiKey }
    }

    // MARK: - Chat

    private var chat: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        if thread.isEmpty && !loading {
                            UpperLabel(text: "Prueba a preguntar", p: p).padding(.top, 6)
                            ForEach(suggestions, id: \.self) { s in
                                Button { prompt = s; send() } label: {
                                    HStack {
                                        Text(s).font(.fig(14, .medium)).foregroundColor(p.ink)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                        Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .semibold)).foregroundColor(p.acc)
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        ForEach(Array(thread.enumerated()), id: \.offset) { i, turn in
                            bubble(turn.question, mine: true)
                            bubble(turn.answer, mine: false).id(i)
                        }
                        if loading {
                            HStack(spacing: 8) {
                                ProgressView().tint(p.acc)
                                Text("Pensando…").font(.fig(13, .medium)).foregroundColor(p.mute)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .id("loading")
                        }
                        if let e = errorMsg {
                            Text(e).font(.fig(13, .medium)).foregroundColor(p.danger)
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.danger.opacity(0.12)))
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                }
                .onChange(of: thread.count) { _, n in withAnimation { proxy.scrollTo(n - 1, anchor: .bottom) } }
                .onChange(of: loading) { _, l in if l { withAnimation { proxy.scrollTo("loading", anchor: .bottom) } } }
            }
            .scrollDismissesKeyboard(.interactively)

            Rectangle().fill(p.line).frame(height: 1)
            HStack(alignment: .bottom, spacing: 10) {
                TextField("", text: $prompt, prompt: Text("Pregunta a tu coach…").foregroundColor(p.mute.opacity(0.8)), axis: .vertical)
                    .lineLimit(1...4)
                    .font(.fig(15, .medium))
                    .foregroundColor(p.ink)
                    .focused($focused)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(p.line, lineWidth: 1))
                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(p.onacc)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(p.grad))
                        .shadow(color: p.glow1, radius: 10, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty || loading)
                .opacity(prompt.trimmingCharacters(in: .whitespaces).isEmpty || loading ? 0.5 : 1)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
        }
    }

    private func bubble(_ text: String, mine: Bool) -> some View {
        HStack {
            if mine { Spacer(minLength: 40) }
            Text(text)
                .font(.fig(14, mine ? .semibold : .medium))
                .lineSpacing(4)
                .foregroundColor(mine ? p.onacc : p.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(mine ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft))
                )
            if !mine { Spacer(minLength: 24) }
        }
    }

    private func send() {
        let q = prompt.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, !loading else { return }
        prompt = ""
        loading = true
        errorMsg = nil
        focused = false
        let ctx = buildContext()
        Task {
            do {
                let res = try await coach.ask(q, context: ctx)
                thread.append((q, res))
            } catch {
                errorMsg = error.localizedDescription
            }
            loading = false
        }
    }

    /// Rutina, marcas y semana en curso: lo que el coach necesita para responder con datos.
    private func buildContext() -> String {
        var lines: [String] = ["RUTINA SEMANAL:"]
        for day in WorkoutDay.allCases.sorted(by: { $0.weekOrder < $1.weekOrder }) {
            let recs = viewModel.dailyWorkoutRecords[day] ?? []
            guard !recs.isEmpty else { continue }
            let label = viewModel.label(for: day).map { " (\($0))" } ?? ""
            lines.append("\(day.rawValue)\(label):")
            for r in recs {
                guard let ex = viewModel.getExercise(by: r.exerciseId) else { continue }
                let grp = ex.muscleGroup.map { " [\($0)]" } ?? ""
                var line = "  - \(ex.name)\(grp): \(viewModel.meta(for: ex)), descanso \(WorkoutViewModel.restText(ex.restDuration))"
                if let pr = viewModel.personalRecord(for: ex.id), pr.weight > 0 {
                    line += ", récord \(WorkoutViewModel.kg(pr.weight)) (1RM est. \(Int(pr.oneRepMax)) kg)"
                }
                if let last = viewModel.lastPerformance(for: ex.id) {
                    line += ", última serie \(WorkoutViewModel.kg(last.weight)) × \(last.reps)"
                }
                lines.append(line)
            }
        }
        if lines.count == 1 { lines.append("(sin ejercicios todavía)") }
        let w = viewModel.weekStats(), prev = viewModel.weekStats(offset: -1)
        lines.append("ESTA SEMANA: \(w.sessions) sesiones, \(w.sets) series, \(Int(w.volume)) kg de volumen. Semana anterior: \(prev.sessions) sesiones, \(prev.sets) series, \(Int(prev.volume)) kg.")
        lines.append("Racha: \(viewModel.consecutiveWorkoutDays()) días.")
        return lines.joined(separator: "\n")
    }
}
