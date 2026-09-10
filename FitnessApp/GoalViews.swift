//
//  GoalViews.swift
//  ChamaFit
//
//  Anillo de sesiones de la semana (Inicio) y tarjeta del récord objetivo
//  de un ejercicio (detalle).
//

import SwiftUI

/// "2/3" dentro de un anillo: sesiones de esta semana frente al objetivo.
struct WeekGoalRing: View {
    let done: Int
    let goal: Int
    let p: Palette

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().stroke(p.soft, lineWidth: 3)
                Circle().trim(from: 0, to: goal > 0 ? min(1, Double(done) / Double(goal)) : 0)
                    .stroke(p.hgrad, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if done >= goal {
                    Image(systemName: "checkmark").font(.system(size: 8, weight: .heavy)).foregroundColor(p.acc)
                }
            }
            .frame(width: 16, height: 16)
            Text("\(done)/\(goal) semana").font(.fig(12, .semibold)).foregroundColor(p.ink)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(p.card))
        .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("home.weekGoal")
        .accessibilityLabel("Sesiones esta semana: \(done) de \(goal)")
    }
}

struct GoalCard: View {
    let exercise: Exercise
    let p: Palette
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var editing = false
    @State private var draft: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                UpperLabel(text: "Objetivo", p: p)
                Spacer()
                Button(exercise.goalWeight == nil ? "Poner objetivo" : (editing ? "Cancelar" : "Cambiar")) {
                    if !editing { draft = exercise.goalWeight ?? Self.startDraft(viewModel.personalRecord(for: exercise.id)?.weight ?? exercise.weight) }
                    editing.toggle()
                }
                .font(.fig(12, .semibold)).foregroundColor(p.acc)
                .accessibilityIdentifier("goal.edit")
            }
            if editing {
                HStack(spacing: 8) {
                    Text(WorkoutViewModel.kg(draft)).font(.bri(24)).foregroundColor(p.ink).monospacedDigit()
                        .accessibilityIdentifier("goal.value")
                    Spacer()
                    step("−5") { draft = max(0, draft - 5) }
                    step("−2,5") { draft = max(0, draft - 2.5) }
                    step("+2,5") { draft += 2.5 }
                    step("+5") { draft += 5 }
                }
                HStack(spacing: 8) {
                    if exercise.goalWeight != nil {
                        SoftButton(title: "Quitar", height: 40, fontSize: 13, color: p.danger, filled: false, p: p) {
                            viewModel.setGoalWeight(nil, for: exercise.id); editing = false
                        }
                    }
                    PrimaryButton(title: "Guardar objetivo", height: 40, fontSize: 13, enabled: draft > 0, p: p) {
                        viewModel.setGoalWeight(draft, for: exercise.id); editing = false
                        HapticManager.shared.success()
                    }
                    .accessibilityIdentifier("goal.save")
                }
            } else if let g = viewModel.goalProgress(for: exercise) {
                HStack(alignment: .firstTextBaseline) {
                    Text(WorkoutViewModel.kg(g.best)).font(.bri(22)).foregroundColor(p.ink)
                    Text("de \(WorkoutViewModel.kg(g.goal))").font(.fig(13, .medium)).foregroundColor(p.mute)
                    Spacer()
                    Text("\(Int((g.fraction * 100).rounded())) %").font(.bri(16)).foregroundStyle(p.hgrad)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(p.card)
                        Capsule().fill(p.hgrad).frame(width: geo.size.width * g.fraction)
                    }
                }
                .frame(height: 8)
                Text(etaText(g)).font(.fig(12, .medium)).foregroundColor(g.reached ? p.acc : p.mute)
                    .accessibilityIdentifier("goal.eta")
            } else {
                Text("Pon un peso a batir y te digo cuándo llegarás a tu ritmo.")
                    .font(.fig(12, .medium)).foregroundColor(p.mute)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
    }

    private func etaText(_ g: GoalProgress) -> String {
        if g.reached { return "¡Conseguido! Pon uno nuevo." }
        guard let eta = g.eta else { return "Aún no hay tendencia clara: sigue sumando sesiones." }
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "d 'de' MMMM"
        return "A este ritmo, hacia el \(f.string(from: eta))."
    }

    private func step(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button { action(); HapticManager.shared.selectionFeedback() } label: {
            Text(title).font(.fig(12, .bold)).foregroundColor(p.ink)
                .frame(width: 44, height: 36)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(p.card))
        }
        .buttonStyle(.plain)
    }

    /// Por defecto, un 10 % por encima del récord redondeado a 2,5.
    static func startDraft(_ best: Double) -> Double {
        best > 0 ? PlateMath.roundToLoadable(best * 1.1) : 20
    }
}
