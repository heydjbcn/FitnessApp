//
//  RecoveryViews.swift
//  ChamaFit
//
//  Tarjeta de Recuperación en Inicio (sueño, pulso en reposo, VFC, pasos y
//  anillos, con un semáforo para la sesión de hoy) y su detalle.
//

import SwiftUI

extension Recovery.Level {
    func color(_ p: Palette) -> Color {
        switch self {
        case .good: return Color(hex: "#34D399")
        case .normal: return Pulso.warning(isDark: p.dark)
        case .easy: return Pulso.danger(isDark: p.dark)
        }
    }
    var icon: String {
        switch self { case .good: return "bolt.heart.fill"; case .normal: return "heart.fill"; case .easy: return "bed.double.fill" }
    }
}

struct RecoveryCard: View {
    let p: Palette
    @ObservedObject private var health = HealthManager.shared
    @State private var showingDetail = false
    @AppStorage("hideRecoveryCard", store: AppDefaults.store) private var hidden = false

    var body: some View {
        if !health.isAvailable || hidden {
            EmptyView()
        } else if !health.connected {
            connectCard
        } else {
            Button { showingDetail = true } label: { card }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home.recovery")
                .sheet(isPresented: $showingDetail) { RecoveryDetailSheet(p: p) }
                .task { await health.refresh() }
        }
    }

    private var card: some View {
        let r = health.recovery
        let level = r.level
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: level?.icon ?? "heart.text.square")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(level?.color(p) ?? p.mute)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill((level?.color(p) ?? p.mute).opacity(0.16)))
                VStack(alignment: .leading, spacing: 1) {
                    UpperLabel(text: "Recuperación", p: p)
                    Text(r.headline).font(.fig(15, .bold)).foregroundColor(p.ink)
                }
                Spacer()
                if let move = r.move, let ex = r.exercise, let stand = r.stand {
                    ActivityRings(move: move, exercise: ex, stand: stand).frame(width: 38, height: 38)
                }
            }
            HStack(spacing: 8) {
                metric("Sueño", r.sleepHours.map { Self.hours($0) } ?? "—", "moon.fill")
                metric("Reposo", r.restingHR.map { "\(Int($0.rounded())) ppm" } ?? "—", "heart.fill")
                metric("VFC", r.hrv.map { "\(Int($0.rounded())) ms" } ?? "—", "waveform.path.ecg")
                metric("Pasos", r.steps.map { Self.steps($0) } ?? "—", "figure.walk")
            }
        }
        .padding(14)
        .pulsoCard(p, radius: 22)
    }

    private var connectCard: some View {
        HStack(spacing: 12) {
            IconTile(symbol: "heart.text.square.fill", p: p)
            VStack(alignment: .leading, spacing: 2) {
                Text("¿Cómo llegas hoy?").font(.fig(14, .bold)).foregroundColor(p.ink)
                Text("Conecta Salud: sueño, pulsaciones y pasos, y guarda tus entrenos.")
                    .font(.fig(12, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Button { Task { await health.requestAccess() } } label: {
                Text("Conectar").font(.fig(12, .bold)).foregroundColor(p.onacc)
                    .padding(.horizontal, 12).frame(height: 32).background(Capsule().fill(p.hgrad))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .pulsoCard(p, radius: 22)
        .contextMenu { Button("No mostrar más") { hidden = true } }
    }

    private func metric(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold)).foregroundColor(p.acc)
            Text(value).font(.fig(13, .bold)).foregroundColor(p.ink).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.fig(10, .medium)).foregroundColor(p.mute)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.soft))
    }

    static func hours(_ h: Double) -> String {
        let m = Int((h * 60).rounded())
        return "\(m / 60) h \(String(format: "%02d", m % 60))"
    }

    static func steps(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1f k", Double(n) / 1000).replacingOccurrences(of: ".", with: ",") : "\(n)"
    }
}

/// Los tres anillos de Actividad, pequeños.
struct ActivityRings: View {
    let move: Double
    let exercise: Double
    let stand: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let line = w * 0.13
            ZStack {
                ring(move, Color(red: 0.98, green: 0.07, blue: 0.31), w, line)
                ring(exercise, Color(red: 0.62, green: 0.98, blue: 0.0), w - line * 2.3, line)
                ring(stand, Color(red: 0.0, green: 0.9, blue: 0.95), w - line * 4.6, line)
            }
            .frame(width: w, height: w)
        }
        .accessibilityLabel("Anillos: moverse \(Int(move * 100)) %, ejercicio \(Int(exercise * 100)) %, de pie \(Int(stand * 100)) %")
    }

    private func ring(_ v: Double, _ c: Color, _ size: CGFloat, _ line: CGFloat) -> some View {
        ZStack {
            Circle().stroke(c.opacity(0.22), lineWidth: line)
            Circle().trim(from: 0, to: min(1, v)).stroke(c, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

struct RecoveryDetailSheet: View {
    let p: Palette
    @ObservedObject private var health = HealthManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let r = health.recovery
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "Recuperación de hoy", p: p)
                    Text(r.headline).font(.bri(24)).em(-0.02, size: 24).foregroundColor(r.level?.color(p) ?? p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(r.advice).font(.fig(14, .medium)).lineSpacing(4).foregroundColor(p.ink)
                    row("Sueño de anoche", r.sleepHours.map { RecoveryCard.hours($0) } ?? "Sin datos",
                        health.weekSleepAvg.map { "media 7 días: \(RecoveryCard.hours($0))" }, "moon.fill")
                    row("Pulso en reposo", r.restingHR.map { "\(Int($0.rounded())) ppm" } ?? "Sin datos",
                        r.restingHRAvg.map { "tu media: \(Int($0.rounded())) ppm" }, "heart.fill")
                    row("Variabilidad (VFC)", r.hrv.map { "\(Int($0.rounded())) ms" } ?? "Sin datos",
                        r.hrvAvg.map { "tu media: \(Int($0.rounded())) ms" }, "waveform.path.ecg")
                    row("Pasos hoy", r.steps.map { "\($0)" } ?? "Sin datos",
                        health.weekStepsAvg.map { "media 7 días: \($0)" }, "figure.walk")
                    row("Energía activa", r.activeEnergy.map { "\(Int($0)) kcal" } ?? "Sin datos",
                        r.exerciseMinutes.map { "\(Int($0)) min de ejercicio" }, "flame.fill")
                    Text("Orientativo, no es consejo médico. Sale de Salud: el sueño y el pulso los registra el Apple Watch.")
                        .font(.fig(11, .medium)).foregroundColor(p.mute).padding(.top, 6)
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        }
        .task { await health.refresh() }
    }

    private func row(_ title: String, _ value: String, _ sub: String?, _ icon: String) -> some View {
        HStack(spacing: 12) {
            IconTile(symbol: icon, p: p)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.fig(13, .medium)).foregroundColor(p.mute)
                Text(value).font(.bri(18)).foregroundColor(p.ink)
            }
            Spacer()
            if let sub { Text(sub).font(.fig(11, .medium)).foregroundColor(p.mute).multilineTextAlignment(.trailing) }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
    }
}

/// Historial: la semana según Salud (sueño y pasos medios).
struct HealthWeekCard: View {
    let p: Palette
    @ObservedObject private var health = HealthManager.shared

    var body: some View {
        if health.isAvailable && health.connected && (health.weekSleepAvg != nil || health.weekStepsAvg != nil) {
            HStack(spacing: 10) {
                item("Sueño medio", health.weekSleepAvg.map { RecoveryCard.hours($0) } ?? "—", "moon.fill")
                item("Pasos al día", health.weekStepsAvg.map { "\($0)" } ?? "—", "figure.walk")
            }
            .padding(14)
            .pulsoCard(p, radius: 22)
            .overlay(alignment: .topLeading) {
                UpperLabel(text: "Salud · últimos 7 días", p: p).padding(.leading, 16).padding(.top, -18)
            }
            .padding(.top, 12)
        }
    }

    private func item(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(p.acc)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.bri(18)).foregroundColor(p.ink)
                Text(label).font(.fig(11, .medium)).foregroundColor(p.mute)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}
