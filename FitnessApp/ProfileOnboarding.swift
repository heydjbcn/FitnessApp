//
//  ProfileOnboarding.swift
//  ChamaFit
//
//  Primera vez en la app: nombre → objetivo → nivel → días y minutos →
//  material → preferencias → cómo empezar. «Ahora no» en cada paso. Los
//  mismos bloques se usan en Ajustes › Tu perfil de entreno.
//

import SwiftUI

/// Cómo quiere empezar al acabar el onboarding.
enum OnboardingStart { case ai, program, sample, manual }

struct ProfileOnboardingView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    let onDone: (OnboardingStart) -> Void

    @State private var step = 0
    @State private var name = ""
    @State private var profile = TrainingProfile()
    @FocusState private var nameFocused: Bool

    private var p: Palette { themeManager.p }
    private static let steps = 7
    private var validName: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var canUseAI: Bool {
        AppDefaults.has("--fake-ai") || OnDeviceCoach.isAvailable || AICoachManager.shared.hasKey
    }

    var body: some View {
        ZStack {
            p.bg.ignoresSafeArea()
            Circle()
                .fill(RadialGradient(colors: [p.glow1, .clear], center: .center, startRadius: 0, endRadius: 210))
                .frame(width: 420, height: 420)
                .frame(maxHeight: .infinity, alignment: .top)
                .offset(y: -160)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if step == 0 {
                nameStep
            } else {
                VStack(spacing: 0) {
                    topBar
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text((title).loc).font(.bri(28)).em(-0.03, size: 28).foregroundColor(p.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text((subtitle).loc).font(.fig(14, .medium)).lineSpacing(4).foregroundColor(p.mute)
                                .padding(.top, 6).padding(.bottom, 20)
                                .fixedSize(horizontal: false, vertical: true)
                            stepContent
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    if step < Self.steps - 1 {
                        HStack(spacing: 10) {
                            SoftButton(title: "Atrás", height: 52, p: p) { go(step - 1) }
                                .frame(width: 104)
                            PrimaryButton(title: "Siguiente", icon: nil, height: 52, fontSize: 16, p: p) { go(step + 1) }
                                .accessibilityIdentifier("onboarding.next")
                        }
                        .padding(.horizontal, 24).padding(.bottom, 20)
                    }
                }
                .transition(.opacity)
            }
        }
        .keyboardDoneButton()
    }

    // MARK: - Paso 0: nombre (la bienvenida de siempre)

    private var nameStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(p.onacc)
                    .frame(width: 112, height: 112)
                    .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(p.grad))
                    .shadow(color: p.glow1, radius: 30, y: 24)
                Text("CHAMAFIT").font(.fig(12, .bold)).tracking(1.7).foregroundColor(p.mute).padding(.top, 28)
                HStack(spacing: 0) {
                    Text("Entrena con ").font(.bri(34)).em(-0.03, size: 34).foregroundColor(p.ink)
                    GradientText(text: "pulso", font: .bri(34), p: p, tracking: -0.03 * 34)
                }
                .padding(.top, 8)
                Text("Para personalizar tu experiencia, cuéntanos tu nombre.")
                    .font(.fig(15, .medium)).lineSpacing(5).foregroundColor(p.mute)
                    .multilineTextAlignment(.center).frame(maxWidth: 290).padding(.top, 12)
            }
            Spacer()
            VStack(spacing: 12) {
                TextField("", text: $name, prompt: Text("Tu nombre").foregroundColor(p.mute.opacity(0.8)))
                    .font(.fig(17, .semibold)).foregroundColor(p.ink)
                    .multilineTextAlignment(.center)
                    .focused($nameFocused)
                    .submitLabel(.continue)
                    .onSubmit(saveName)
                    .frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.card))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(p.line, lineWidth: 1))
                PrimaryButton(title: "Continuar", icon: nil, height: 54, fontSize: 16, enabled: validName, p: p, action: saveName)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 28)
    }

    private func saveName() {
        guard validName else { return }
        userManager.saveUserProfile(name: name, age: userManager.userAge, height: userManager.userHeight,
                                    weight: userManager.userWeight)
        HapticManager.shared.success()
        nameFocused = false
        // Recién llegado: la unidad de partida, la de su región (se puede cambiar en «Preferencias»).
        if AppDefaults.store.string(forKey: Units.key) == nil { Units.weight = Units.regionSuggestion }
        go(1)
    }

    // MARK: - Pasos del perfil

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 5) {
                ForEach(1..<Self.steps, id: \.self) { i in
                    Capsule().fill(i <= step ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft))
                        .frame(width: i == step ? 22 : 8, height: 6)
                }
            }
            Spacer()
            if step < Self.steps - 1 {
                Button("Ahora no") { skip() }
                    .font(.fig(13, .semibold)).foregroundColor(p.mute)
                    .accessibilityIdentifier("onboarding.skip")
            }
        }
        .padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 18)
    }

    private var title: String {
        switch step {
        case 1: return "¿Qué quieres conseguir?"
        case 2: return "¿Cuánto llevas entrenando?"
        case 3: return "¿Cuánto puedes entrenar?"
        case 4: return "¿Con qué material?"
        case 5: return "¿Algo a tener en cuenta?"
        default: return "¿Cómo quieres empezar?"
        }
    }

    private var subtitle: String {
        switch step {
        case 1: return "Lo usamos para proponerte rutinas, series y repeticiones."
        case 2: return "Así no te sugerimos ni demasiado ni demasiado poco."
        case 3: return "Tu objetivo semanal sale de aquí. Lo cambias cuando quieras."
        case 4: return "Solo te propondremos ejercicios que puedas hacer. Puedes tener varios: gimnasio, casa…"
        case 5: return "Opcional. Todo esto se queda en tu iPhone."
        default: return String(localized: "Tu perfil está listo, \(userManager.userName). Elige por dónde seguir.")
        }
    }

    @ViewBuilder private var stepContent: some View {
        switch step {
        case 1: GoalPicker(goal: $profile.goal, p: p)
        case 2: LevelPicker(level: $profile.level, p: p)
        case 3: DaysMinutesPicker(days: $profile.daysPerWeek, minutes: $profile.minutes, p: p)
        case 4: EquipmentPicker(selected: equipmentBinding, p: p)
        case 5: PreferencesEditor(profile: $profile, p: p)
        default: startOptions
        }
    }

    private var recommendedProgram: String {
        let eq = viewModel.equipmentProfiles.first { $0.id == (profile.equipmentProfileId ?? EquipmentProfile.gymId) } ?? EquipmentProfile.presets[0]
        return ProgramTemplates.recommended(for: profile, equipment: eq).first?.name ?? "Full body 3 días"
    }

    private var equipmentBinding: Binding<UUID> {
        Binding(get: { profile.equipmentProfileId ?? EquipmentProfile.gymId },
                set: { profile.equipmentProfileId = $0 })
    }

    private var startOptions: some View {
        VStack(spacing: 10) {
            OptionCard(icon: "wand.and.stars", title: "Crear mi plan con IA",
                       detail: canUseAI ? "Una rutina hecha para tu perfil. La revisas antes de guardarla."
                                        : "Necesita Apple Intelligence o una API key de Claude (Ajustes › Coach).",
                       selected: false, enabled: canUseAI, p: p) { finish(.ai) }
                .accessibilityIdentifier("onboarding.start.ai")
            OptionCard(icon: "chart.line.uptrend.xyaxis", title: "Seguir un programa",
                       detail: String(localized: "Plantillas de 8 a 12 semanas con progresión y descargas. Te recomendamos: \(recommendedProgram)."),
                       selected: false, p: p) { finish(.program) }
                .accessibilityIdentifier("onboarding.start.program")
            OptionCard(icon: "list.bullet.rectangle", title: "Empezar con una rutina de ejemplo",
                       detail: "Cinco días ya montados que puedes cambiar a tu gusto.",
                       selected: false, p: p) { finish(.sample) }
                .accessibilityIdentifier("onboarding.start.sample")
            OptionCard(icon: "hand.point.up.left.fill", title: "La monto yo",
                       detail: "Te enseñamos a crear tu primer ejercicio paso a paso.",
                       selected: false, p: p) { finish(.manual) }
                .accessibilityIdentifier("onboarding.start.manual")
        }
    }

    private func go(_ next: Int) {
        HapticManager.shared.buttonTapped()
        withAnimation(.easeInOut(duration: 0.25)) { step = max(1, min(Self.steps - 1, next)) }
    }

    /// «Ahora no»: se queda lo elegido hasta aquí, sin darlo por completo.
    private func skip() {
        var saved = profile
        saved.completed = false
        viewModel.trainingProfile = saved
        onDone(.manual)
    }

    private func finish(_ start: OnboardingStart) {
        var saved = profile
        saved.completed = true
        viewModel.trainingProfile = saved
        HapticManager.shared.success()
        onDone(start)
    }
}

// MARK: - Bloques reutilizables

/// Tarjeta de opción grande con icono, título y explicación.
struct OptionCard: View {
    let icon: String
    let title: String
    var detail: String? = nil
    let selected: Bool
    var enabled: Bool = true
    let p: Palette
    let action: () -> Void

    var body: some View {
        Button(action: { HapticManager.shared.selectionFeedback(); action() }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(selected ? p.onacc : p.acc)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selected ? AnyShapeStyle(p.grad) : AnyShapeStyle(p.soft)))
                VStack(alignment: .leading, spacing: 3) {
                    Text((title).loc).font(.fig(16, .bold)).foregroundColor(p.ink)
                    if let detail {
                        Text((detail).loc).font(.fig(12, .medium)).foregroundColor(p.mute)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 20)).foregroundColor(p.acc)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(p.card))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(selected ? p.acc : p.line, lineWidth: selected ? 1.5 : 1))
            .opacity(enabled ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct GoalPicker: View {
    @Binding var goal: TrainingProfile.Goal
    let p: Palette

    var body: some View {
        VStack(spacing: 10) {
            ForEach(TrainingProfile.Goal.allCases) { g in
                OptionCard(icon: g.icon, title: g.label, selected: goal == g, p: p) { goal = g }
                    .accessibilityIdentifier("profile.goal.\(g.rawValue)")
            }
        }
    }
}

struct LevelPicker: View {
    @Binding var level: TrainingProfile.Level
    let p: Palette

    var body: some View {
        VStack(spacing: 10) {
            ForEach(TrainingProfile.Level.allCases) { l in
                OptionCard(icon: l == .beginner ? "leaf.fill" : l == .intermediate ? "flame.fill" : "bolt.fill",
                           title: l.label, detail: l.detail, selected: level == l, p: p) { level = l }
                    .accessibilityIdentifier("profile.level.\(l.rawValue)")
            }
        }
    }
}

struct DaysMinutesPicker: View {
    @Binding var days: Int
    @Binding var minutes: Int
    let p: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            UpperLabel(text: "Días por semana", p: p).padding(.bottom, 10)
            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { d in
                    ChoiceChip(text: "\(d)", selected: days == d, p: p) { days = d }
                        .accessibilityIdentifier("profile.days.\(d)")
                }
            }
            UpperLabel(text: "Minutos por sesión", p: p).padding(.top, 24).padding(.bottom, 10)
            HStack(spacing: 6) {
                ForEach([30, 45, 60, 75, 90], id: \.self) { m in
                    ChoiceChip(text: "\(m)", selected: minutes == m, p: p) { minutes = m }
                        .accessibilityIdentifier("profile.minutes.\(m)")
                }
            }
            Text("\(days) \(days == 1 ? "sesión" : "sesiones") de unos \(minutes) min: \(days * minutes / 60) h \(days * minutes % 60 == 0 ? "" : "\(days * minutes % 60) min ")a la semana.")
                .font(.fig(13, .medium)).foregroundColor(p.mute).padding(.top, 18)
        }
    }
}

/// Píldora de selección que ocupa su parte de la fila.
struct ChoiceChip: View {
    let text: String
    let selected: Bool
    let p: Palette
    let action: () -> Void

    var body: some View {
        Button(action: { HapticManager.shared.selectionFeedback(); action() }) {
            Text((text).loc).font(.fig(15, selected ? .bold : .semibold))
                .foregroundColor(selected ? p.onacc : p.ink)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? .clear : p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Elegir perfil de material y retocar lo que tiene.
struct EquipmentPicker: View {
    @Binding var selected: UUID
    let p: Palette
    @EnvironmentObject var viewModel: WorkoutViewModel

    var body: some View {
        let profiles = viewModel.equipmentProfiles
        VStack(alignment: .leading, spacing: 10) {
            ForEach(profiles) { e in
                OptionCard(icon: e.id == EquipmentProfile.gymId ? "building.2.fill"
                                 : e.id == EquipmentProfile.homeId ? "house.fill"
                                 : e.id == EquipmentProfile.bodyweightId ? "figure.core.training" : "bag.fill",
                           title: e.name, detail: e.summary, selected: selected == e.id, p: p) { selected = e.id }
                    .accessibilityIdentifier("profile.equipment.\(e.name)")
            }
            if let current = profiles.first(where: { $0.id == selected }) {
                UpperLabel(text: String(localized: "Qué tienes en «\(current.name)»"), p: p).padding(.top, 14).padding(.bottom, 2)
                FlowLayout(spacing: 6) {
                    ForEach(Equipment.allCases) { item in
                        let on = current.items.contains(item)
                        TagChip(text: item.label, icon: item.icon, selected: on, p: p) {
                            var edited = current
                            if on { edited.items.remove(item) } else { edited.items.insert(item) }
                            viewModel.saveEquipmentProfile(edited)
                        }
                        .accessibilityIdentifier("equipment.item.\(item.rawValue)")
                    }
                }
                if current.items.contains(.barbell) {
                    HStack {
                        Text("Barra").font(.fig(14, .semibold)).foregroundColor(p.ink)
                        Spacer()
                        Button { var e = current; e.barWeight = max(5, Units.stepped(e.barWeight, by: -1)); viewModel.saveEquipmentProfile(e) } label: { Image(systemName: "minus") }
                            .accessibilityIdentifier("equipment.bar.minus")
                        Text((Units.format(current.barWeightKg)).loc).font(.bri(15)).foregroundColor(p.ink).frame(minWidth: 70)
                            .accessibilityIdentifier("equipment.bar")
                        Button { var e = current; e.barWeight = Units.stepped(e.barWeight, by: 1); viewModel.saveEquipmentProfile(e) } label: { Image(systemName: "plus") }
                    }
                    .font(.system(size: 14, weight: .bold)).foregroundColor(p.acc)
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
            }
        }
    }
}

/// Etiqueta pequeña que se enciende y apaga.
struct TagChip: View {
    let text: String
    var icon: String? = nil
    let selected: Bool
    let p: Palette
    let action: () -> Void

    var body: some View {
        Button(action: { HapticManager.shared.selectionFeedback(); action() }) {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon).font(.system(size: 11, weight: .semibold)) }
                Text((text).loc).font(.fig(13, selected ? .bold : .semibold))
            }
            .foregroundColor(selected ? p.onacc : p.mute)
            .padding(.horizontal, 12).frame(height: 34)
            .background(Capsule().fill(selected ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
            .overlay(Capsule().strokeBorder(selected ? .clear : p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Grupos a priorizar, ejercicios a evitar y molestias.
struct PreferencesEditor: View {
    @Binding var profile: TrainingProfile
    let p: Palette
    @State private var showAllAvoid = false
    @State private var unit = Units.weight

    static let groups = ["Pecho", "Espalda", "Hombros", "Bíceps", "Tríceps", "Piernas", "Glúteos", "Core", "Cardio"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            UpperLabel(text: "Peso en", p: p).padding(.bottom, 10)
            HStack(spacing: 6) {
                ForEach(WeightUnit.allCases) { u in
                    ChoiceChip(text: u.label, selected: unit == u, p: p) { unit = u; Units.weight = u }
                        .accessibilityIdentifier("profile.unit.\(u.rawValue)")
                }
            }
            .padding(.bottom, 24)
            UpperLabel(text: "Quiero trabajar más", p: p).padding(.bottom, 10)
            FlowLayout(spacing: 6) {
                ForEach(Self.groups, id: \.self) { g in
                    TagChip(text: g, selected: profile.focusGroups.contains(g), p: p) {
                        toggle(g, in: &profile.focusGroups)
                    }
                    .accessibilityIdentifier("profile.focus.\(g)")
                }
            }
            UpperLabel(text: "Lesiones o molestias", p: p).padding(.top, 24).padding(.bottom, 10)
            TextField("", text: $profile.limitations,
                      prompt: Text("P. ej. hombro derecho, lumbares…").foregroundColor(p.mute.opacity(0.8)),
                      axis: .vertical)
                .font(.fig(15, .semibold)).foregroundColor(p.ink)
                .lineLimit(2...4)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(p.line, lineWidth: 1))
                .accessibilityIdentifier("profile.limitations")
            UpperLabel(text: "Prefiero no hacer", p: p).padding(.top, 24).padding(.bottom, 10)
            let names = ExerciseCatalog.all.map(\.name)
            let shown = showAllAvoid ? names : Array(names.prefix(12)) + profile.avoidExercises.filter { !names.prefix(12).contains($0) }
            FlowLayout(spacing: 6) {
                ForEach(shown, id: \.self) { n in
                    TagChip(text: n, selected: profile.avoidExercises.contains(n), p: p) {
                        toggle(n, in: &profile.avoidExercises)
                    }
                }
            }
            if !showAllAvoid {
                Button("Ver todos los ejercicios") { showAllAvoid = true }
                    .font(.fig(13, .semibold)).foregroundColor(p.acc).padding(.top, 10)
            }
        }
    }

    private func toggle(_ value: String, in list: inout [String]) {
        if let i = list.firstIndex(of: value) { list.remove(at: i) } else { list.append(value) }
    }
}

/// Coloca los hijos en filas, saltando de línea cuando no caben.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowH = max(rowH, size.height)
        }
        return CGSize(width: proposal.width ?? maxX, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}

// MARK: - Ajustes › Tu perfil de entreno

struct TrainingProfileSheet: View {
    /// Pestaña con la que se abre (3 = material).
    var initialSection = 0

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var profile = TrainingProfile()
    @State private var loaded = false
    @State private var section = 0

    private var p: Palette { themeManager.p }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "Ajustes", p: p)
                    Text("Tu perfil de entreno").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(["Objetivo", "Nivel", "Días", "Material", "Preferencias"].enumerated()), id: \.offset) { i, t in
                        TagChip(text: t, selected: section == i, p: p) { section = i }
                            .accessibilityIdentifier("profile.tab.\(i)")
                    }
                }
                .padding(.horizontal, 22)
            }
            .padding(.top, 14)

            ScrollView(showsIndicators: false) {
                Group {
                    switch section {
                    case 0: GoalPicker(goal: $profile.goal, p: p)
                    case 1: LevelPicker(level: $profile.level, p: p)
                    case 2: DaysMinutesPicker(days: $profile.daysPerWeek, minutes: $profile.minutes, p: p)
                    case 3: EquipmentPicker(selected: Binding(get: { profile.equipmentProfileId ?? EquipmentProfile.gymId },
                                                              set: { profile.equipmentProfileId = $0 }), p: p)
                    default: PreferencesEditor(profile: $profile, p: p)
                    }
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        } footer: {
            SheetFooter(p: p) {
                PrimaryButton(title: "Guardar", icon: "checkmark", height: 50, p: p) {
                    var saved = profile
                    saved.completed = true
                    viewModel.trainingProfile = saved
                    HapticManager.shared.success()
                    dismiss()
                }
                .accessibilityIdentifier("profile.save")
            }
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            profile = viewModel.trainingProfile
            section = initialSection
        }
    }
}
