//
//  MuscleMapView.swift
//  ChamaFit
//
//  Mapa muscular de la semana: una silueta geométrica de frente y de
//  espaldas, al estilo «Pulso», con cada grupo coloreado por las series
//  hechas frente a las 10-20 recomendadas. Tocar una zona dice cuántas.
//

import SwiftUI

enum MuscleZone {
    /// Rango semanal orientativo para hipertrofia.
    static let target = 10...20

    static func verdict(_ sets: Int) -> String {
        if sets == 0 { return "sin trabajar esta semana" }
        if sets < target.lowerBound { return "por debajo de lo recomendado (10-20)" }
        if sets > target.upperBound { return "por encima de lo recomendado (10-20)" }
        return "en el rango recomendado (10-20)"
    }
}

struct MuscleMapView: View {
    /// Series de la semana por grupo ("Pecho": 12…).
    let sets: [String: Int]
    let p: Palette
    @State private var selected: String? = nil

    private struct Piece: Identifiable {
        let id = UUID()
        let group: String?
        let rect: CGRect
        let radius: CGFloat
        var ellipse = false
    }

    // Lienzo de 100 × 210 por figura.
    private static func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x, y: y, width: w, height: h) }

    private static let common: [Piece] = [
        Piece(group: nil, rect: r(40, 2, 20, 24), radius: 0, ellipse: true),           // cabeza
        Piece(group: nil, rect: r(45, 23, 10, 9), radius: 3),                          // cuello
        Piece(group: "Hombros", rect: r(21, 30, 19, 17), radius: 0, ellipse: true),
        Piece(group: "Hombros", rect: r(60, 30, 19, 17), radius: 0, ellipse: true),
        Piece(group: nil, rect: r(9, 74, 9, 32), radius: 4),                           // antebrazos
        Piece(group: nil, rect: r(82, 74, 9, 32), radius: 4),
        Piece(group: nil, rect: r(34, 154, 12, 40), radius: 6),                        // gemelos (frente)
        Piece(group: nil, rect: r(54, 154, 12, 40), radius: 6),
    ]

    private static let front: [Piece] = common + [
        Piece(group: "Pecho", rect: r(30, 33, 19, 22), radius: 7),
        Piece(group: "Pecho", rect: r(51, 33, 19, 22), radius: 7),
        Piece(group: "Bíceps", rect: r(14, 47, 11, 26), radius: 5),
        Piece(group: "Bíceps", rect: r(75, 47, 11, 26), radius: 5),
        Piece(group: "Core", rect: r(37, 58, 12, 11), radius: 3),
        Piece(group: "Core", rect: r(51, 58, 12, 11), radius: 3),
        Piece(group: "Core", rect: r(37, 71, 12, 11), radius: 3),
        Piece(group: "Core", rect: r(51, 71, 12, 11), radius: 3),
        Piece(group: "Core", rect: r(37, 84, 12, 11), radius: 3),
        Piece(group: "Core", rect: r(51, 84, 12, 11), radius: 3),
        Piece(group: nil, rect: r(33, 97, 34, 8), radius: 4),                          // cadera
        Piece(group: "Piernas", rect: r(32, 106, 17, 46), radius: 8),
        Piece(group: "Piernas", rect: r(51, 106, 17, 46), radius: 8),
    ]

    private static let back: [Piece] = [
        Piece(group: nil, rect: r(40, 2, 20, 24), radius: 0, ellipse: true),
        Piece(group: nil, rect: r(45, 23, 10, 9), radius: 3),
        Piece(group: "Hombros", rect: r(21, 30, 19, 17), radius: 0, ellipse: true),
        Piece(group: "Hombros", rect: r(60, 30, 19, 17), radius: 0, ellipse: true),
        Piece(group: "Espalda", rect: r(30, 32, 40, 32), radius: 9),
        Piece(group: "Espalda", rect: r(36, 66, 28, 28), radius: 7),
        Piece(group: "Tríceps", rect: r(14, 47, 11, 26), radius: 5),
        Piece(group: "Tríceps", rect: r(75, 47, 11, 26), radius: 5),
        Piece(group: nil, rect: r(9, 74, 9, 32), radius: 4),
        Piece(group: nil, rect: r(82, 74, 9, 32), radius: 4),
        Piece(group: "Glúteos", rect: r(32, 96, 17, 19), radius: 0, ellipse: true),
        Piece(group: "Glúteos", rect: r(51, 96, 17, 19), radius: 0, ellipse: true),
        Piece(group: "Piernas", rect: r(32, 117, 17, 35), radius: 8),
        Piece(group: "Piernas", rect: r(51, 117, 17, 35), radius: 8),
        Piece(group: "Piernas", rect: r(34, 154, 12, 40), radius: 6),
        Piece(group: "Piernas", rect: r(54, 154, 12, 40), radius: 6),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 20) {
                figure(Self.front, title: "Frente")
                figure(Self.back, title: "Espalda")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 250)

            if let g = selected {
                let n = sets[g] ?? 0
                HStack(spacing: 8) {
                    Circle().fill(fill(for: g)).frame(width: 10, height: 10)
                    Text("\(g) · \(n) \(n == 1 ? "serie" : "series") esta semana, \(MuscleZone.verdict(n))")
                        .font(.fig(13, .semibold)).foregroundColor(p.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityIdentifier("muscle.selected")
            } else {
                Text("Toca una zona para ver sus series.").font(.fig(12, .medium)).foregroundColor(p.mute)
            }

            HStack(spacing: 12) {
                legend("0", p.soft)
                legend("1-9", p.acc.opacity(0.45))
                legend("10-20", p.acc.opacity(0.8))
                legend("+20", p.acc)
                Spacer()
                if let cardio = sets["Cardio"], cardio > 0 {
                    Label("\(cardio) cardio", systemImage: "heart.fill").font(.fig(11, .semibold)).foregroundColor(p.mute)
                }
            }
        }
    }

    private func figure(_ pieces: [Piece], title: String) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let s = min(geo.size.width / 100, geo.size.height / 210)
                let dx = (geo.size.width - 100 * s) / 2
                ZStack(alignment: .topLeading) {
                    ForEach(pieces) { piece in
                        let rect = CGRect(x: dx + piece.rect.minX * s, y: piece.rect.minY * s,
                                          width: piece.rect.width * s, height: piece.rect.height * s)
                        shape(piece, rect)
                    }
                }
            }
            Text(title.uppercased()).font(.fig(10, .bold)).tracking(0.8).foregroundColor(p.mute)
        }
        .frame(maxWidth: 130)
    }

    @ViewBuilder private func shape(_ piece: Piece, _ rect: CGRect) -> some View {
        let isSel = piece.group != nil && piece.group == selected
        let base: AnyShape = piece.ellipse ? AnyShape(Ellipse()) : AnyShape(RoundedRectangle(cornerRadius: piece.radius * rect.width / piece.rect.width, style: .continuous))
        base
            .fill(piece.group.map { fill(for: $0) } ?? p.soft.opacity(0.6))
            .overlay(base.stroke(isSel ? p.ink : p.line, lineWidth: isSel ? 1.6 : 0.8))
            .frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
            .contentShape(Rectangle())
            .onTapGesture {
                guard let g = piece.group else { return }
                withAnimation(.easeOut(duration: 0.15)) { selected = selected == g ? nil : g }
                HapticManager.shared.selectionFeedback()
            }
            .accessibilityElement()
            .accessibilityLabel(piece.group.map { "\($0): \(sets[$0] ?? 0) series" } ?? "")
            .accessibilityHidden(piece.group == nil)
            .accessibilityAddTraits(piece.group == nil ? [] : .isButton)
    }

    private func fill(for group: String) -> Color {
        let n = sets[group] ?? 0
        switch n {
        case 0: return p.soft
        case ..<MuscleZone.target.lowerBound: return p.acc.opacity(0.45)
        case MuscleZone.target: return p.acc.opacity(0.8)
        default: return p.acc
        }
    }

    private func legend(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(p.line, lineWidth: 0.8))
            Text(label).font(.fig(11, .medium)).foregroundColor(p.mute)
        }
    }
}
