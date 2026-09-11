//
//  ProgressCharts.swift
//  ChamaFit
//
//  Gráfica de progreso de un ejercicio (Swift Charts) en estilo «Pulso»:
//  peso máximo, volumen o 1RM estimado por sesión, a elegir.
//

import SwiftUI
import Charts

struct ExerciseProgressChart: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    let exerciseId: UUID

    @State private var mode = 0   // 0 peso máx · 1 volumen · 2 1RM
    private var p: Palette { themeManager.p }

    private struct Point: Identifiable {
        let date: Date
        let value: Double
        var id: Date { date }
    }

    private var points: [Point] {
        switch mode {
        case 1: return viewModel.exerciseDailyVolume(for: exerciseId).map { Point(date: $0.date, value: $0.volume) }
        case 2: return viewModel.exerciseDailyOneRepMax(for: exerciseId).map { Point(date: $0.date, value: $0.oneRepMax) }
        default: return viewModel.exerciseDailyMaxWeight(for: exerciseId).map { Point(date: $0.date, value: $0.weight) }
        }
    }

    private var unit: String { mode == 1 ? "kg" : "kg" }

    private func format(_ v: Double) -> String {
        if mode == 1 && v >= 1000 { return AppLanguage.decimal(String(format: "%.1f t", v / 1000)) }
        return WorkoutViewModel.kg(v)
    }

    var body: some View {
        let data = points
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PulsoSegmented(options: ["Peso máx", "Volumen", "1RM"], selection: $mode, onCard: false, p: p)
                Spacer()
                if let last = data.last {
                    Text((format(last.value)).loc)
                        .font(.bri(16))
                        .foregroundStyle(p.hgrad)
                }
            }

            if data.count >= 2 {
                Chart(data) { pt in
                    if mode == 1 {
                        BarMark(x: .value("Fecha", pt.date, unit: .day), y: .value(unit, pt.value))
                            .foregroundStyle(p.hgrad)
                            .cornerRadius(4)
                    } else {
                        AreaMark(x: .value("Fecha", pt.date), y: .value(unit, pt.value))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(LinearGradient(colors: [p.acc.opacity(0.25), .clear],
                                                            startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Fecha", pt.date), y: .value(unit, pt.value))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(p.hgrad)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        PointMark(x: .value("Fecha", pt.date), y: .value(unit, pt.value))
                            .foregroundStyle(p.acc)
                            .symbolSize(30)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: mode == 1))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(p.line)
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .foregroundStyle(p.mute)
                            .font(.fig(10, .medium))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(p.line)
                        AxisValueLabel().foregroundStyle(p.mute).font(.fig(10, .medium))
                    }
                }
                .frame(height: 170)
                .padding(.top, 4)

                if let first = data.first?.value, let last = data.last?.value, first > 0 {
                    let delta = (last - first) / first * 100
                    Text((delta >= 0 ? "▲ \(Int(delta.rounded())) % desde la primera sesión" : String(localized: "▼ \(Int((-delta).rounded())) % desde la primera sesión")).loc)
                        .font(.fig(12, .semibold))
                        .foregroundColor(delta >= 0 ? Pulso.ok(isDark: p.dark) : p.danger)
                }
            } else {
                Text(data.isEmpty
                     ? "Aún no hay series registradas. La gráfica aparece con dos sesiones."
                     : "Una sesión registrada. Con la siguiente verás la tendencia.")
                    .font(.fig(13, .medium))
                    .lineSpacing(3)
                    .foregroundColor(p.mute)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(p.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .pulsoCard(p, radius: 20)
    }
}
