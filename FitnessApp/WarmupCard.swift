//
//  WarmupCard.swift
//  ChamaFit
//
//  Tarjetas de la sugerencia de peso y del calentamiento. El calentamiento
//  es una guía para ir tachando: no se apunta como series (no gasta las
//  series del ejercicio ni ensucia el historial).
//

import SwiftUI

struct SuggestionCard: View {
    let suggestion: WeightSuggestion
    let p: Palette

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: suggestion.arrow)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(suggestion.trend == .up ? p.onacc : p.acc)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(suggestion.trend == .up ? AnyShapeStyle(p.grad) : AnyShapeStyle(p.soft)))
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    UpperLabel(text: "Hoy toca", p: p)
                    Spacer()
                    Text(suggestion.text).font(.bri(17)).foregroundColor(p.ink)
                }
                Text(suggestion.reason)
                    .font(.fig(12, .medium))
                    .lineSpacing(2)
                    .foregroundColor(p.mute)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("detail.suggestion")
    }
}

struct WarmupCard: View {
    /// Peso de la primera serie de trabajo.
    let work: Double
    let p: Palette
    var bar: Double = 20

    @State private var done: Set<Int> = []

    private var sets: [PlateMath.WarmupSet] { PlateMath.warmup(for: work, bar: bar) }

    var body: some View {
        if !sets.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    UpperLabel(text: "Calentamiento", p: p)
                    Spacer()
                    Text("antes de \(WorkoutViewModel.kg(work))").font(.fig(11, .medium)).foregroundColor(p.mute)
                }
                ForEach(Array(sets.enumerated()), id: \.offset) { i, s in
                    let on = done.contains(i)
                    Button {
                        if on { done.remove(i) } else { done.insert(i) }
                        HapticManager.shared.selectionFeedback()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(on ? p.acc : p.mute)
                            Text("\(WorkoutViewModel.kg(s.weight)) × \(s.reps)")
                                .font(.fig(14, .bold))
                                .foregroundColor(on ? p.mute : p.ink)
                                .strikethrough(on)
                            Spacer()
                            Text(PlateMath.sideText(target: s.weight, bar: bar) + (s.weight > bar ? " por lado" : ""))
                                .font(.fig(12, .medium))
                                .foregroundColor(p.mute)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.card))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("warmup.\(i)")
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
        }
    }
}
