//
//  WatchHomeView.swift
//  ChamaFit Watch
//
//  La sesión del día en la muñeca con el estilo «Pulso»: el descanso en
//  cuenta atrás cuando lo hay, las pulsaciones si hay sesión abierta, y cada
//  ejercicio con sus series para marcar (+) o deshacer (−).
//

import SwiftUI
import WatchKit

struct WatchHomeView: View {
    @EnvironmentObject var sync: WatchConnectivityManager
    @EnvironmentObject var workout: WorkoutSessionManager
    @State private var restFinishedAt: Date? = nil

    private var a1: Color { Color(hex: sync.accent1) }
    private var a2: Color { Color(hex: sync.accent2) }
    private var grad: LinearGradient { LinearGradient(colors: [a1, a2], startPoint: .topLeading, endPoint: .bottomTrailing) }
    private var onAcc: Color { sync.onAccentDark ? WatchStyle.bg : .white }

    var body: some View {
        NavigationStack {
            Group {
                if sync.exercises.isEmpty { empty } else { list }
            }
            .background(WatchStyle.bg.ignoresSafeArea())
            .navigationTitle(sync.dayName.isEmpty ? "ChamaFit" : sync.dayName)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { sessionButton }
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
            // Cuando el descanso vence, un toque en la muñeca; el iPhone ya avisa por su lado.
            if let end = sync.timerEnd, end <= now, restFinishedAt != end {
                restFinishedAt = end
                WKInterfaceDevice.current().play(.notification)
            }
        }
    }

    // MARK: - Cabecera

    private var sessionButton: some View {
        Button {
            if workout.isRunning { workout.end() } else { workout.start() }
            WKInterfaceDevice.current().play(.click)
        } label: {
            Image(systemName: workout.isRunning ? "stop.fill" : "heart.fill")
                .foregroundColor(workout.isRunning ? WatchStyle.danger : a2)
        }
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(grad)
            Text("Abre ChamaFit en el iPhone para traer la sesión de hoy")
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(WatchStyle.mute)
        }
        .padding()
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 8) {
                if !sync.sessionLabel.isEmpty {
                    Text(sync.sessionLabel)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(grad)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if sync.restActive, let end = sync.timerEnd { restCard(end) }
                if workout.isRunning { vitalsCard }
                ForEach(sync.exercises) { ex in exerciseCard(ex) }
                summary
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Descanso

    private func restCard(_ end: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("DESCANSO")
                    .font(.system(size: 10, weight: .bold)).tracking(0.8)
                    .foregroundColor(onAcc.opacity(0.8))
                Spacer()
                Text(timerInterval: Date()...end, countsDown: true)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(onAcc)
            }
            Text(sync.timerLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(onAcc.opacity(0.85))
                .lineLimit(1)
            HStack(spacing: 6) {
                Button("+30 s") { sync.extendTimer(); WKInterfaceDevice.current().play(.click) }
                    .buttonStyle(WatchPill(fill: onAcc.opacity(0.18), text: onAcc))
                Button("Parar") { sync.stopTimer(); WKInterfaceDevice.current().play(.click) }
                    .buttonStyle(WatchPill(fill: onAcc, text: sync.onAccentDark ? .white : WatchStyle.bg))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(grad))
    }

    // MARK: - Pulsaciones

    private var vitalsCard: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "heart.fill").foregroundColor(WatchStyle.danger)
                Text(workout.heartRate > 0 ? "\(Int(workout.heartRate))" : "–")
                    .font(.system(size: 18, weight: .bold, design: .rounded)).monospacedDigit()
                Text("ppm").font(.system(size: 10, weight: .medium)).foregroundColor(WatchStyle.mute)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundColor(a2)
                Text("\(Int(workout.activeCalories))")
                    .font(.system(size: 18, weight: .bold, design: .rounded)).monospacedDigit()
                Text("kcal").font(.system(size: 10, weight: .medium)).foregroundColor(WatchStyle.mute)
            }
            Spacer()
            Text(workout.elapsedText)
                .font(.system(size: 13, weight: .semibold, design: .rounded)).monospacedDigit()
                .foregroundColor(WatchStyle.mute)
        }
        .foregroundColor(WatchStyle.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(WatchStyle.card))
    }

    // MARK: - Ejercicio

    private func exerciseCard(_ ex: WatchExercise) -> some View {
        let done = ex.completed >= ex.totalSets
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ex.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(WatchStyle.ink)
                        .lineLimit(2)
                    Text(ex.meta)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(WatchStyle.mute)
                }
                Spacer(minLength: 4)
                if ex.superset >= 0 {
                    Text("SS \(String(UnicodeScalar(UInt8(65 + ex.superset))))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(a2)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Capsule().fill(WatchStyle.soft))
                }
            }
            HStack(spacing: 5) {
                ForEach(0..<max(0, ex.totalSets), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(i < ex.completed ? AnyShapeStyle(grad) : AnyShapeStyle(WatchStyle.soft))
                        .frame(width: 14, height: 14)
                }
                Spacer(minLength: 4)
                Button {
                    sync.undoSet(ex.id)
                    WKInterfaceDevice.current().play(.directionDown)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(WatchStyle.ink)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(WatchStyle.soft))
                }
                .buttonStyle(.plain)
                .disabled(ex.completed == 0)
                .opacity(ex.completed == 0 ? 0.35 : 1)
                Button {
                    sync.completeSet(ex.id)
                    WKInterfaceDevice.current().play(.success)
                } label: {
                    Image(systemName: done ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(onAcc)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(grad))
                }
                .buttonStyle(.plain)
                .disabled(done)
                .opacity(done ? 0.5 : 1)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(WatchStyle.card))
    }

    private var summary: some View {
        let done = sync.exercises.reduce(0) { $0 + $1.completed }
        let total = sync.exercises.reduce(0) { $0 + $1.totalSets }
        return HStack {
            Text("\(done)/\(total) series")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(WatchStyle.mute)
            Spacer()
            if let t = sync.lastSync {
                Text(t, style: .time)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(WatchStyle.mute.opacity(0.7))
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}

// MARK: - Estilo «Pulso» en el reloj

enum WatchStyle {
    static let bg = Color(hex: "#0B0A14")
    static let card = Color.white.opacity(0.08)
    static let soft = Color.white.opacity(0.14)
    static let ink = Color(hex: "#F4F3FF")
    static let mute = Color(hex: "#8E8CA8")
    static let danger = Color(hex: "#FB7185")
}

struct WatchPill: ButtonStyle {
    let fill: Color
    let text: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(text)
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(Capsule().fill(fill))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        self.init(red: Double((rgb >> 16) & 0xFF) / 255, green: Double((rgb >> 8) & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255)
    }
}
