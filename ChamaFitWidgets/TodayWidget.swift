//
//  TodayWidget.swift
//  ChamaFitWidgets
//
//  Widget de pantalla de inicio: la sesión de hoy, cuánto llevas y qué toca.
//  Lee el resumen que la app deja en el App Group.
//

import SwiftUI
import WidgetKit

struct TodayEntry: TimelineEntry {
    let date: Date
    let summary: TodaySummary?
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), summary: TodaySummary(dayName: "Jueves", sessionLabel: "Hombro y core", exerciseCount: 5,
                                                      doneSets: 4, totalSets: 16, nextExercise: "Elevaciones laterales",
                                                      streak: 6, accent1: "#8B5CF6", accent2: "#22D3EE", onAccentDark: true))
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(TodayEntry(date: Date(), summary: TodaySummary.load() ?? placeholder(in: context).summary))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = TodayEntry(date: Date(), summary: TodaySummary.load())
        // Se refresca cuando la app lo pide; por si acaso, a medianoche.
        let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86_400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ChamaFitToday", provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetStyle.bg }
        }
        .configurationDisplayName("Sesión de hoy")
        .description("Lo que toca hoy y cuánto llevas hecho.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

private struct TodayWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let s = entry.summary, family == .accessoryCircular || family == .accessoryRectangular || family == .accessoryInline {
            LockScreenView(s: s, family: family)
        } else if let s = entry.summary {
            content(s)
        } else if family == .accessoryInline {
            Text("ChamaFit")
        } else {
            VStack(spacing: 6) {
                Image(systemName: "dumbbell.fill").font(.system(size: 22, weight: .semibold)).foregroundColor(WidgetStyle.mute)
                Text("Abre ChamaFit").font(.system(size: 12, weight: .semibold)).foregroundColor(WidgetStyle.mute)
            }
        }
    }

    private func content(_ s: TodaySummary) -> some View {
        let grad = WidgetStyle.gradient(s.accent1, s.accent2, horizontal: true)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(s.dayName.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(WidgetStyle.mute)
                Spacer()
                if s.streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill").font(.system(size: 10, weight: .semibold))
                        Text("\(s.streak)").font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(WidgetStyle.color(s.accent2))
                }
            }

            if s.isRestDay {
                Text("Día libre")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(WidgetStyle.ink)
                    .padding(.top, 4)
                Text("Sin ejercicios programados")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(WidgetStyle.mute)
                Spacer(minLength: 0)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int((s.progress * 100).rounded()))%")
                        .font(.system(size: family == .systemSmall ? 30 : 34, weight: .bold, design: .rounded))
                        .foregroundStyle(grad)
                    Text("\(s.doneSets)/\(s.totalSets) series")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(WidgetStyle.mute)
                }
                .padding(.top, 2)
                if let label = s.sessionLabel {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(WidgetStyle.ink)
                        .lineLimit(1)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(WidgetStyle.soft)
                        Capsule().fill(grad).frame(width: geo.size.width * s.progress)
                    }
                }
                .frame(height: 6)
                .padding(.top, 8)
                Spacer(minLength: 0)
                if let next = s.nextExercise {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.right").font(.system(size: 10, weight: .bold))
                        Text(next).lineLimit(1)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(WidgetStyle.mute)
                } else {
                    Text("Sesión completada")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(WidgetStyle.color(s.accent2))
                }
            }
        }
    }
}

// MARK: - Pantalla bloqueada y esfera

/// Monocromo, como pide la pantalla bloqueada: anillo de series, siguiente
/// ejercicio y racha.
private struct LockScreenView: View {
    let s: TodaySummary
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: s.progress) {
                Image(systemName: "dumbbell.fill")
            } currentValueLabel: {
                Text(s.isRestDay ? "—" : "\(s.doneSets)")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetAccentable()
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(s.isRestDay ? "Día libre" : (s.sessionLabel ?? s.dayName))
                    .font(.headline).widgetAccentable().lineLimit(1)
                if !s.isRestDay {
                    Text("\(s.doneSets)/\(s.totalSets) series").font(.caption)
                    if let next = s.nextExercise {
                        Text("→ \(next)").font(.caption).lineLimit(1)
                    } else {
                        Text("Sesión completada").font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            if s.isRestDay {
                Text("Día libre · racha \(s.streak)")
            } else {
                Text("\(s.doneSets)/\(s.totalSets) series · \(s.sessionLabel ?? s.dayName)")
            }
        }
    }
}
