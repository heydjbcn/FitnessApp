//
//  ProgressCharts.swift
//  FitnessApp
//
//  Gráficas de progreso con Swift Charts (nativo iOS 16+):
//  peso máx por ejercicio en el tiempo y peso corporal.
//

import SwiftUI
import Charts

/// Gráfica de progreso (peso máximo por fecha) de un ejercicio.
struct ExerciseProgressChart: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    let exerciseId: UUID

    private var isDark: Bool { themeManager.isDarkMode }

    var body: some View {
        let data = viewModel.exerciseDailyMaxWeight(for: exerciseId)
        VStack(alignment: .leading, spacing: 10) {
            Text("PROGRESO · PESO MÁX")
                .font(AppFonts.label).tracking(1.0)
                .foregroundColor(AppColors.textSecondary(isDark: isDark))

            if data.count >= 2 {
                Chart {
                    ForEach(data, id: \.date) { p in
                        LineMark(x: .value("Fecha", p.date), y: .value("kg", p.weight))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppColors.primary(themeManager: themeManager))
                        PointMark(x: .value("Fecha", p.date), y: .value("kg", p.weight))
                            .foregroundStyle(AppColors.primary(themeManager: themeManager))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(AppColors.hairline(isDark: isDark))
                        AxisValueLabel()
                    }
                }
                .frame(height: 170)
            } else {
                Text("Registra al menos 2 sesiones para ver tu progreso.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: isDark))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            }
        }
        .padding(16)
        .cardStyle(isDarkMode: isDark)
    }
}

/// Resumen semanal: volumen total + series por grupo muscular (barras).
struct WeeklyMuscleSummary: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    private var isDark: Bool { themeManager.isDarkMode }

    private func volStr(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1ft", v / 1000) : "\(Int(v)) kg"
    }

    var body: some View {
        let groups = viewModel.setsByMuscleGroup()
        let maxSets = max(groups.map { $0.sets }.max() ?? 1, 1)
        let vol = viewModel.weeklyVolume()
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ESTA SEMANA · POR MÚSCULO")
                    .font(AppFonts.label).tracking(1.0)
                    .foregroundColor(AppColors.textSecondary(isDark: isDark))
                Spacer()
                if vol > 0 {
                    Text(volStr(vol))
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
            }
            if groups.isEmpty {
                Text("Registra series para ver tu reparto por grupo muscular.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: isDark))
            } else {
                ForEach(groups, id: \.group) { g in
                    HStack(spacing: 10) {
                        Text(g.group)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textPrimary(isDark: isDark))
                            .frame(width: 78, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(AppColors.hairline(isDark: isDark))
                                Capsule().fill(AppColors.primary(themeManager: themeManager))
                                    .frame(width: max(8, geo.size.width * CGFloat(g.sets) / CGFloat(maxSets)))
                            }
                        }
                        .frame(height: 10)
                        Text("\(g.sets)")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: isDark))
                            .frame(width: 26, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle(isDarkMode: isDark)
    }
}

/// Gráfica de evolución del peso corporal.
struct BodyWeightChart: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager

    private var isDark: Bool { themeManager.isDarkMode }

    var body: some View {
        let data = viewModel.bodyWeightSeries()
        VStack(alignment: .leading, spacing: 10) {
            Text("PESO CORPORAL")
                .font(AppFonts.label).tracking(1.0)
                .foregroundColor(AppColors.textSecondary(isDark: isDark))

            if data.count >= 2 {
                Chart {
                    ForEach(data, id: \.date) { p in
                        LineMark(x: .value("Fecha", p.date), y: .value("kg", p.weight))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppColors.primary(themeManager: themeManager))
                        AreaMark(x: .value("Fecha", p.date), y: .value("kg", p.weight))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppColors.primary(themeManager: themeManager).opacity(0.12))
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(AppColors.hairline(isDark: isDark))
                        AxisValueLabel()
                    }
                }
                .frame(height: 170)
            } else {
                Text("Registra tu peso en Historial para ver la evolución.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: isDark))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            }
        }
        .padding(16)
        .cardStyle(isDarkMode: isDark)
    }
}
