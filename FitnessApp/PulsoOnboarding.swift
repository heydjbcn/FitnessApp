//
//  PulsoOnboarding.swift
//  FitnessApp
//
//  Primera vez en la app, como en el prototipo: la pantalla "Entrena con
//  pulso" que pide el nombre, y después el tutorial de siete pasos que va
//  moviéndose por las pestañas.
//

import SwiftUI

// MARK: - Bienvenida

struct PulsoWelcomeView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var themeManager: ThemeManager
    let onDone: () -> Void

    @State private var name = ""
    @FocusState private var focused: Bool

    private var p: Palette { themeManager.p }
    private var valid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            p.bg.ignoresSafeArea()
            Circle()
                .fill(RadialGradient(colors: [p.glow1, .clear], center: .center, startRadius: 0, endRadius: 210))
                .frame(width: 420, height: 420)
                .frame(maxHeight: .infinity, alignment: .top)
                .offset(y: -140)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 0) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(p.onacc)
                        .frame(width: 112, height: 112)
                        .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(p.grad))
                        .shadow(color: p.glow1, radius: 30, y: 24)
                    Text("CHAMAFIT")
                        .font(.fig(12, .bold))
                        .tracking(1.7)
                        .foregroundColor(p.mute)
                        .padding(.top, 28)
                    HStack(spacing: 0) {
                        Text("Entrena con ")
                            .font(.bri(34))
                            .em(-0.03, size: 34)
                            .foregroundColor(p.ink)
                        GradientText(text: "pulso", font: .bri(34), p: p, tracking: -0.03 * 34)
                    }
                    .padding(.top, 8)
                    Text("Para personalizar tu experiencia, cuéntanos tu nombre.")
                        .font(.fig(15, .medium))
                        .lineSpacing(5)
                        .foregroundColor(p.mute)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 290)
                        .padding(.top, 12)
                }
                Spacer()

                VStack(spacing: 12) {
                    TextField("", text: $name, prompt: Text("Tu nombre").foregroundColor(p.mute.opacity(0.8)))
                        .font(.fig(17, .semibold))
                        .foregroundColor(p.ink)
                        .multilineTextAlignment(.center)
                        .focused($focused)
                        .submitLabel(.continue)
                        .onSubmit(save)
                        .frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.card))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(p.line, lineWidth: 1))
                    PrimaryButton(title: "Continuar", icon: nil, height: 54, fontSize: 16, enabled: valid, p: p, action: save)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 28)
        }
    }

    private func save() {
        guard valid else { return }
        userManager.saveUserProfile(name: name, age: userManager.userAge, height: userManager.userHeight,
                                    weight: userManager.userWeight)
        HapticManager.shared.success()
        onDone()
    }
}

// MARK: - Tutorial

/// Los siete pasos del prototipo. Cada paso lleva a su pestaña.
enum TutorialStep: Int, CaseIterable {
    case welcome, create, days, created, calendar, sets, done

    var title: String {
        switch self {
        case .welcome: return "¡Bienvenido!"
        case .create: return "Crear ejercicio"
        case .days: return "Seleccionar días"
        case .created: return "Ejercicio creado"
        case .calendar: return "En el calendario"
        case .sets: return "Marcar series"
        case .done: return "¡Listo!"
        }
    }

    var text: String {
        switch self {
        case .welcome: return "Te guiaremos en la creación de tu primer ejercicio paso a paso."
        case .create: return "Completa el formulario con los datos de tu ejercicio: nombre, repeticiones, peso y series."
        case .days: return "Elige qué días de la semana quieres realizar este ejercicio."
        case .created: return "¡Perfecto! Tu ejercicio aparece en la lista de ejercicios disponibles."
        case .calendar: return "En Calendario ves tu semana: qué toca cada día y cuánto llevas hecho."
        case .sets: return "En Inicio, toca los círculos para marcar cada serie completada. El descanso arranca solo."
        case .done: return "Ya sabes cómo crear y usar ejercicios. ¡Hora de entrenar!"
        }
    }

    var icon: String {
        switch self {
        case .welcome: return "hand.wave.fill"
        case .create: return "plus.circle.fill"
        case .days: return "calendar"
        case .created: return "checkmark.circle.fill"
        case .calendar: return "calendar.badge.plus"
        case .sets: return "checkmark.circle.fill"
        case .done: return "star.fill"
        }
    }

    /// Pestaña en la que se explica cada paso.
    var tab: Int? {
        switch self {
        case .welcome: return nil
        case .create, .days, .created: return 2
        case .calendar: return 1
        case .sets, .done: return 0
        }
    }
}

struct TutorialOverlay: View {
    @Binding var step: TutorialStep?
    @Binding var selectedTab: Int
    let onCreate: () -> Void

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager

    private var p: Palette { themeManager.p }

    var body: some View {
        if let current = step {
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [.clear, Color(red: 5/255, green: 4/255, blue: 12/255).opacity(0.55)],
                               startPoint: UnitPoint(x: 0.5, y: 0.4), endPoint: .bottom)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                card(current)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 96)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func card(_ s: TutorialStep) -> some View {
        let last = TutorialStep.allCases.count - 1
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: s.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(p.onacc)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.grad))
                VStack(alignment: .leading, spacing: 2) {
                    Text("TUTORIAL · \(s.rawValue + 1) DE \(TutorialStep.allCases.count)")
                        .font(.fig(11, .bold)).tracking(0.9).foregroundColor(p.mute)
                    Text(s.title).font(.bri(19)).em(-0.02, size: 19).foregroundColor(p.ink)
                }
                Spacer(minLength: 0)
                Button("Saltar") { go(nil) }
                    .font(.fig(12, .semibold))
                    .foregroundColor(p.mute)
            }

            Text(s.text)
                .font(.fig(14, .medium))
                .lineSpacing(5)
                .foregroundColor(p.mute)
                .padding(.top, 12)

            if s == .create || s == .days {
                SoftButton(title: "Crear ejercicio ahora", height: 42, p: p, action: onCreate)
                    .padding(.top, 12)
            }
            if (s == .welcome || s.rawValue == last) && viewModel.availableExercises.isEmpty {
                SoftButton(title: "Atajo: cargar rutina de ejemplo", height: 42, p: p) {
                    viewModel.loadSampleRoutine()
                }
                .padding(.top, 12)
            }

            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    ForEach(TutorialStep.allCases, id: \.self) { d in
                        Capsule()
                            .fill(d == s ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft))
                            .frame(width: d == s ? 18 : 6, height: 6)
                    }
                }
                Spacer()
                if s.rawValue > 0 {
                    Button("Anterior") { go(TutorialStep(rawValue: s.rawValue - 1)) }
                        .font(.fig(13, .semibold))
                        .foregroundColor(p.ink)
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
                }
                Button(s.rawValue == last ? "¡A entrenar!" : "Siguiente") {
                    go(TutorialStep(rawValue: s.rawValue + 1))
                }
                .font(.fig(13, .bold))
                .foregroundColor(p.onacc)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background(Capsule().fill(p.hgrad))
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .background(RoundedRectangle(cornerRadius: 25, style: .continuous).fill(p.sheet))
        .padding(1.5)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(p.grad))
        .shadow(color: p.glow1, radius: 25, y: 20)
    }

    /// Cambia de paso y lleva a su pestaña; nil cierra el tutorial en Inicio.
    private func go(_ next: TutorialStep?) {
        HapticManager.shared.buttonTapped()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            step = next
            if let tab = next?.tab { selectedTab = tab }
            if next == nil { selectedTab = 0 }
        }
    }
}
