//
//  CoachAIView.swift
//  ChamaFit
//
//  Coach IA en estilo «Pulso». Dos motores: la IA del iPhone (Apple
//  Intelligence: gratis, sin key, sin internet) y Claude (con tu key). Las
//  respuestas van apareciendo mientras se escriben. Desde aquí también se
//  analiza la semana y se crea una rutina entera con IA.
//

import SwiftUI

enum CoachEngine: String { case apple, claude }

struct CoachAIView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var coach = AICoachManager.shared
    @ObservedObject private var health = HealthManager.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("coachEngine", store: AppDefaults.store) private var engineRaw = CoachEngine.apple.rawValue
    /// Datos de Salud en el contexto: sí con el motor del iPhone (no sale de él), no con Claude salvo que lo pidas.
    @AppStorage("coachHealthApple", store: AppDefaults.store) private var healthApple = true
    @AppStorage("coachHealthClaude", store: AppDefaults.store) private var healthClaude = false
    @State private var showingContext = false

    @State private var prompt = ""
    @State private var thread: [(question: String, answer: String)] = []
    @State private var loading = false
    @State private var errorMsg: String?
    @State private var keyDraft = ""
    @State private var showingKey = false
    @State private var showingGenerator = false
    @State private var streamTask: Task<Void, Never>? = nil
    @FocusState private var focused: Bool

    private var p: Palette { themeManager.p }
    private var appleOK: Bool { OnDeviceCoach.isAvailable }
    /// El motor que se usa de verdad: si el elegido no está disponible, el otro.
    private var engine: CoachEngine {
        let wanted = CoachEngine(rawValue: engineRaw) ?? .apple
        if wanted == .apple && !appleOK { return .claude }
        return wanted
    }
    private var needsKey: Bool { engine == .claude && (!coach.hasKey || showingKey) }

    private let suggestions = [
        "Ajusta mi rutina del lunes para ganar fuerza",
        "¿Estoy entrenando equilibrado por grupos musculares?",
        "Dame un calentamiento para piernas",
        "¿Cómo progreso de peso sin estancarme?"
    ]

    var body: some View {
        PulsoSheet(p: p) {
            header
            if appleOK {
                PulsoSegmented(options: ["iPhone · gratis", "Claude"],
                               selection: Binding(get: { engine == .apple ? 0 : 1 },
                                                  set: { engineRaw = ($0 == 0 ? CoachEngine.apple : .claude).rawValue }),
                               onCard: false, p: p)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .accessibilityIdentifier("coach.engine")
            }
            if !needsKey { privacyRow }
            if needsKey { keyEntry } else { chat }
        }
        .sheet(isPresented: $showingContext) { contextSheet }
        .sheet(isPresented: $showingGenerator) {
            RoutineGeneratorSheet(engine: engine)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .onDisappear { streamTask?.cancel() }
    }

    // MARK: - Qué ve el coach

    private var includeHealth: Bool { engine == .apple ? healthApple : healthClaude }

    private var privacyRow: some View {
        HStack(spacing: 10) {
            Image(systemName: engine == .apple ? "lock.iphone" : "network")
                .font(.system(size: 13, weight: .semibold)).foregroundColor(p.acc)
            VStack(alignment: .leading, spacing: 1) {
                Text("Incluir mis datos de Salud").font(.fig(13, .semibold)).foregroundColor(p.ink)
                Text(engine == .apple ? "Sueño y pulso · no salen de tu iPhone" : "Sueño y pulso · se enviarían a Anthropic")
                    .font(.fig(11, .medium)).foregroundColor(p.mute)
            }
            Spacer(minLength: 4)
            Button("Ver lo que se envía") { showingContext = true }
                .font(.fig(11, .bold)).foregroundColor(p.acc)
                .accessibilityIdentifier("coach.context")
            PulsoToggle(isOn: engine == .apple ? $healthApple : $healthClaude, p: p)
                .accessibilityIdentifier("toggle.coachHealth")
        }
        .padding(.horizontal, 22).padding(.top, 10)
    }

    private var contextSheet: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: engine == .apple ? "Se queda en tu iPhone" : "Se envía a Anthropic con cada pregunta", p: p)
                    Text("Lo que ve el coach").font(.bri(22)).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { showingContext = false }
            }
            .padding(.horizontal, 22).padding(.top, 22)
            ScrollView {
                Text(viewModel.coachContext(compact: engine == .apple, recovery: includeHealth ? health.recovery : nil))
                    .font(.system(size: 12, design: .monospaced)).foregroundColor(p.ink)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.soft))
                    .padding(.horizontal, 22).padding(.vertical, 14)
                    .accessibilityIdentifier("coach.contextText")
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                UpperLabel(text: engine == .apple ? "Apple Intelligence · en tu iPhone" : "Claude", p: p)
                Text("Coach IA").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
            }
            Spacer()
            if engine == .claude && coach.hasKey {
                Button { showingKey = true } label: {
                    Image(systemName: "key.fill")
                        .font(.system(size: 13, weight: .bold)).foregroundColor(p.mute)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(p.soft))
                        .overlay(Circle().strokeBorder(p.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("API key")
                .padding(.trailing, 8)
            }
            CloseCircle(p: p) { dismiss() }
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
    }

    // MARK: - API key

    private var keyEntry: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                IconTile(symbol: "sparkles", size: 56, radius: 18, gradient: true, glow: true, p: p)
                Text("Activa el Coach con Claude")
                    .font(.bri(20)).em(-0.02, size: 20).foregroundColor(p.ink)
                    .padding(.top, 16)
                Text(appleOK
                     ? "Pega tu API key de Anthropic (de pago por uso, se guarda en el llavero de este iPhone). Sin key, usa «iPhone · gratis»."
                     : "Pega tu API key de Anthropic. Es de pago por uso y se guarda en el llavero de este iPhone. \(OnDeviceCoach.unavailableReason)")
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
                        HStack(spacing: 8) {
                            actionChip("Analiza mi semana", icon: "chart.line.uptrend.xyaxis") { analyzeWeek() }
                                .accessibilityIdentifier("coach.analyze")
                            actionChip("Crear rutina con IA", icon: "wand.and.stars") { showingGenerator = true }
                                .accessibilityIdentifier("coach.generate")
                        }
                        .padding(.top, 6)
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
                            if !turn.answer.isEmpty { bubble(turn.answer, mine: false).id(i) }
                        }
                        if loading && (thread.last?.answer.isEmpty ?? true) {
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
                .onChange(of: thread.last?.answer) { _, _ in proxy.scrollTo(thread.count - 1, anchor: .bottom) }
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
                    .accessibilityIdentifier("coach.input")
                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(p.onacc)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(p.grad))
                        .shadow(color: p.glow1, radius: 10, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Enviar")
                .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty || loading)
                .opacity(prompt.trimmingCharacters(in: .whitespaces).isEmpty || loading ? 0.5 : 1)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
        }
    }

    private func actionChip(_ title: String, icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(.fig(13, .bold))
                .foregroundColor(p.onacc)
                .frame(maxWidth: .infinity).frame(height: 40)
                .background(Capsule().fill(p.hgrad))
        }
        .buttonStyle(.plain)
        .disabled(loading)
    }

    private func bubble(_ text: String, mine: Bool) -> some View {
        HStack {
            if mine { Spacer(minLength: 40) }
            Group {
                if mine { Text(text) } else { Text((try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)) }
            }
            .font(.fig(14, mine ? .semibold : .medium))
            .lineSpacing(4)
            .foregroundColor(mine ? p.onacc : p.ink)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(mine ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft))
            )
            if !mine { Spacer(minLength: 24) }
        }
    }

    // MARK: - Envío

    private func analyzeWeek() {
        prompt = "Analiza mi semana de entreno: qué he hecho bien, qué grupos van cortos o sobrados frente a 10-20 series, cómo voy frente a la semana anterior y a mi objetivo de sesiones, y dame tres ajustes concretos para la que viene."
        send()
    }

    private func send() {
        let q = prompt.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, !loading else { return }
        prompt = ""
        loading = true
        errorMsg = nil
        focused = false
        let history = thread.filter { !$0.answer.isEmpty }.map { ($0.question, $0.answer) }
        thread.append((q, ""))
        let index = thread.count - 1
        let useApple = engine == .apple
        let ctx = viewModel.coachContext(compact: useApple, recovery: includeHealth ? health.recovery : nil)
        streamTask = Task {
            do {
                let stream = useApple
                    ? OnDeviceCoach.stream(q, context: ctx, history: history)
                    : coach.stream(q, context: ctx, history: history)
                for try await text in stream where index < thread.count {
                    thread[index].answer = text
                }
                if thread[index].answer.isEmpty { thread[index].answer = "(sin respuesta)" }
            } catch is CancellationError {
            } catch {
                if index < thread.count, thread[index].answer.isEmpty { thread.remove(at: index) }
                errorMsg = error.localizedDescription
            }
            loading = false
        }
    }
}
