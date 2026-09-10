//
//  SetQuickEditor.swift
//  ChamaFit
//
//  Editor rápido de una serie desde Inicio (pulsación larga en una bolita):
//  peso, repeticiones, tipo y RPE con botones grandes, para tocar con el
//  pulgar entre serie y serie sin abrir el detalle del ejercicio.
//

import SwiftUI

struct SetQuickEditor: View {
    let exercise: Exercise
    /// nil = la serie todavía no está hecha: al guardar se marca con estos valores.
    let existing: SetLog?
    let setNumber: Int
    let p: Palette
    let onSave: (Double, Int, SetType, Int?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weight: Double
    @State private var reps: Int
    @State private var type: SetType
    @State private var rpe: Int?

    init(exercise: Exercise, existing: SetLog?, setNumber: Int, suggested: SetLog?, p: Palette,
         onSave: @escaping (Double, Int, SetType, Int?) -> Void) {
        self.exercise = exercise
        self.existing = existing
        self.setNumber = setNumber
        self.p = p
        self.onSave = onSave
        let base = existing ?? suggested
        _weight = State(initialValue: base?.weight ?? exercise.weight)
        _reps = State(initialValue: base?.reps ?? exercise.repetitions)
        _type = State(initialValue: existing?.type ?? .normal)
        _rpe = State(initialValue: existing?.rpe)
    }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "Serie \(setNumber) · \(existing == nil ? "marcar" : "editar")", p: p)
                    Text(exercise.name)
                        .font(.bri(20)).em(-0.02, size: 20)
                        .foregroundColor(p.ink)
                        .lineLimit(1)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)

            VStack(spacing: 10) {
                stepperRow(label: "Peso", value: WorkoutViewModel.kg(weight),
                           minus: { weight = max(0, weight - 2.5) }, plus: { weight += 2.5 },
                           fine: [("−1", { weight = max(0, weight - 1) }), ("+1", { weight += 1 })])
                stepperRow(label: exercise.segundos > 0 ? "Segundos" : "Repeticiones", value: "\(reps)",
                           minus: { reps = max(0, reps - 1) }, plus: { reps += 1 },
                           fine: [("−5", { reps = max(0, reps - 5) }), ("+5", { reps += 5 })])

                HStack(spacing: 6) {
                    ForEach(SetType.allCases, id: \.self) { t in
                        let on = type == t
                        Button { type = t; HapticManager.shared.selectionFeedback() } label: {
                            Text(t.label)
                                .font(.fig(12, on ? .bold : .semibold))
                                .foregroundColor(on ? p.onacc : p.mute)
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(Capsule().fill(on ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 6) {
                    Text("RPE").font(.fig(11, .bold)).tracking(0.5).foregroundColor(p.mute).frame(width: 30)
                    ForEach(6...10, id: \.self) { v in
                        let on = rpe == v
                        Button { rpe = on ? nil : v; HapticManager.shared.selectionFeedback() } label: {
                            Text("\(v)")
                                .font(.bri(14))
                                .foregroundColor(on ? p.onacc : p.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(on ? AnyShapeStyle(p.grad) : AnyShapeStyle(p.soft)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 8)
        } footer: {
            SheetFooter(p: p) {
                PrimaryButton(title: existing == nil ? "Marcar serie" : "Guardar", height: 50, p: p) {
                    onSave(weight, reps, type, rpe)
                    dismiss()
                }
            }
        }
        .presentationDetents([.height(existing == nil ? 430 : 430)])
    }

    private func stepperRow(label: String, value: String, minus: @escaping () -> Void, plus: @escaping () -> Void,
                            fine: [(String, () -> Void)]) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.fig(11, .medium)).foregroundColor(p.mute)
                Text(value).font(.bri(24)).foregroundColor(p.ink).monospacedDigit()
            }
            .frame(minWidth: 96, alignment: .leading)
            Spacer(minLength: 0)
            ForEach(fine.indices, id: \.self) { i in
                smallButton(fine[i].0, fine[i].1)
            }
            bigButton("minus", minus).accessibilityIdentifier("quick.\(label).minus")
            bigButton("plus", plus).accessibilityIdentifier("quick.\(label).plus")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
    }

    private func bigButton(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button { action(); HapticManager.shared.selectionFeedback() } label: {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(p.onacc)
                .frame(width: 44, height: 44)
                .background(Circle().fill(p.grad))
        }
        .buttonStyle(.plain)
    }

    private func smallButton(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button { action(); HapticManager.shared.selectionFeedback() } label: {
            Text(title)
                .font(.fig(12, .bold))
                .foregroundColor(p.ink)
                .frame(width: 40, height: 44)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.card))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
