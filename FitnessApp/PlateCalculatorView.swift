//
//  PlateCalculatorView.swift
//  ChamaFit
//
//  Calculadora de discos en estilo «Pulso»: peso objetivo con botones de
//  ±2,5 y ±5, barra a elegir, y los discos de cada lado dibujados.
//

import SwiftUI

struct PlateCalculatorView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var target: Double
    @State private var barWeight: Double = 20

    private var p: Palette { themeManager.p }
    init(initialWeight: Double = 0) {
        _target = State(initialValue: max(0, initialWeight))
    }

    private var perSide: [(plate: Double, count: Int)] { PlateMath.perSide(target: target, bar: barWeight) }
    private var residual: Double { PlateMath.residual(target: target, bar: barWeight) }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "Qué poner en la barra", p: p)
                    Text("Calculadora de discos").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Peso objetivo
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Peso objetivo").font(.fig(11, .medium)).foregroundColor(p.mute)
                            Text(WorkoutViewModel.kg(target)).font(.bri(28)).foregroundColor(p.ink).monospacedDigit()
                        }
                        Spacer(minLength: 0)
                        small("−5") { target = max(0, target - 5) }
                        small("+5") { target += 5 }
                        big("minus") { target = max(0, target - 2.5) }
                        big("plus") { target += 2.5 }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))

                    // Barra
                    UpperLabel(text: "Barra", p: p).padding(.top, 18).padding(.bottom, 8)
                    HStack(spacing: 6) {
                        ForEach([20.0, 15.0, 10.0], id: \.self) { b in
                            let on = barWeight == b
                            Button { barWeight = b; HapticManager.shared.selectionFeedback() } label: {
                                Text("\(Int(b)) kg")
                                    .font(.fig(13, on ? .bold : .semibold))
                                    .foregroundColor(on ? p.onacc : p.mute)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(Capsule().fill(on ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
                                    .overlay(Capsule().strokeBorder(on ? .clear : p.line, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Resultado
                    UpperLabel(text: "Por cada lado", p: p).padding(.top, 18).padding(.bottom, 8)
                    if target <= barWeight {
                        note(target > 0 ? "El objetivo es igual o menor que la barra." : "Sube el peso objetivo.")
                    } else if perSide.isEmpty {
                        note("No se puede formar con los discos disponibles.")
                    } else {
                        barDrawing.padding(.bottom, 12)
                        VStack(spacing: 6) {
                            ForEach(perSide, id: \.plate) { item in
                                HStack {
                                    plateChip(item.plate)
                                    Text(WorkoutViewModel.kg(item.plate))
                                        .font(.fig(15, .semibold)).foregroundColor(p.ink)
                                    Spacer()
                                    Text("× \(item.count)")
                                        .font(.bri(16)).foregroundStyle(p.hgrad)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.soft))
                            }
                        }
                        if abs(residual) > 0.01 {
                            Text("Aproximado: faltan \(WorkoutViewModel.kg(abs(residual))) para el total exacto.")
                                .font(.fig(12, .semibold))
                                .foregroundColor(Pulso.warning(isDark: p.dark))
                                .padding(.top, 10)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: - Piezas

    /// La barra vista de frente con los discos de un lado, del más pesado al más ligero.
    private var barDrawing: some View {
        HStack(spacing: 3) {
            Capsule().fill(p.mute).frame(width: 34, height: 8)
            ForEach(Array(perSide.enumerated()), id: \.offset) { _, item in
                ForEach(0..<item.count, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(p.grad)
                        .frame(width: max(8, min(18, item.plate * 0.7)), height: plateHeight(item.plate))
                }
            }
            Capsule().fill(p.mute).frame(width: 14, height: 8)
            Spacer(minLength: 0)
        }
        .frame(height: 64)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.card))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(p.line, lineWidth: 1))
    }

    private func plateHeight(_ plate: Double) -> CGFloat {
        switch plate {
        case 25: return 56
        case 20: return 52
        case 15: return 44
        case 10: return 38
        case 5: return 30
        case 2.5: return 24
        default: return 18
        }
    }

    private func plateChip(_ plate: Double) -> some View {
        Text(WorkoutViewModel.number(plate))
            .font(.bri(11))
            .foregroundColor(p.onacc)
            .frame(width: 34, height: 34)
            .background(Circle().fill(p.grad))
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.fig(13, .medium)).foregroundColor(p.mute)
            .frame(maxWidth: .infinity)
            .padding(16)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(p.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
    }

    private func big(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button { action(); HapticManager.shared.selectionFeedback() } label: {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(p.onacc)
                .frame(width: 44, height: 44)
                .background(Circle().fill(p.grad))
        }
        .buttonStyle(.plain)
    }

    private func small(_ title: String, _ action: @escaping () -> Void) -> some View {
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
