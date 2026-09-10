//
//  ChamaFitWatchWidgets.swift
//  ChamaFit Watch · complicaciones
//
//  En la esfera: anillo de series de hoy, lo siguiente y la cuenta atrás del
//  descanso. Tocar abre ChamaFit en el reloj.
//

import SwiftUI
import WidgetKit

struct WatchEntry: TimelineEntry {
    let date: Date
    let state: WatchComplicationState?
}

struct WatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchEntry {
        WatchEntry(date: Date(), state: WatchComplicationState(dayName: "Jueves", label: "Hombro y core", done: 6, total: 16,
                                                              next: "Elevaciones laterales"))
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchEntry) -> Void) {
        completion(WatchEntry(date: Date(), state: WatchComplicationState.load() ?? placeholder(in: context).state))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchEntry>) -> Void) {
        let state = WatchComplicationState.load()
        var entries = [WatchEntry(date: Date(), state: state)]
        // Al acabar el descanso la complicación vuelve a enseñar lo siguiente.
        if let end = state?.restEnd, end > Date() { entries.append(WatchEntry(date: end, state: state)) }
        let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86_400)
        completion(Timeline(entries: entries, policy: .after(midnight)))
    }
}

struct ChamaFitComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ChamaFitWatch", provider: WatchProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("ChamaFit")
        .description("Series de hoy, lo siguiente y el descanso.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}

@main
struct ChamaFitWatchWidgetsBundle: WidgetBundle {
    var body: some Widget { ChamaFitComplication() }
}

private struct ComplicationView: View {
    let entry: WatchEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let s = entry.state
        let resting = (s?.restEnd ?? .distantPast) > entry.date
        switch family {
        case .accessoryCircular:
            if resting, let end = s?.restEnd {
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        Image(systemName: "timer").font(.system(size: 11, weight: .bold))
                        Text(timerInterval: entry.date...end, countsDown: true)
                            .font(.system(size: 13, weight: .bold, design: .rounded)).monospacedDigit()
                            .multilineTextAlignment(.center)
                    }
                }
                .widgetAccentable()
            } else {
                Gauge(value: s?.progress ?? 0) {
                    Image(systemName: "dumbbell.fill")
                } currentValueLabel: {
                    Text("\(s?.done ?? 0)")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .widgetAccentable()
            }
        case .accessoryCorner:
            Image(systemName: resting ? "timer" : "dumbbell.fill")
                .font(.system(size: 20, weight: .semibold))
                .widgetLabel {
                    if resting, let end = s?.restEnd {
                        Text(timerInterval: entry.date...end, countsDown: true)
                    } else {
                        Gauge(value: s?.progress ?? 0) { Text("Series") }
                    }
                }
                .widgetAccentable()
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                if resting, let end = s?.restEnd {
                    Text("Descanso").font(.headline).widgetAccentable()
                    Text(timerInterval: entry.date...end, countsDown: true).font(.title3.monospacedDigit())
                    if let next = s?.next { Text("→ \(next)").font(.caption2).lineLimit(1) }
                } else if let s, s.total > 0 {
                    Text(s.label.isEmpty ? s.dayName : s.label).font(.headline).widgetAccentable().lineLimit(1)
                    Text("\(s.done)/\(s.total) series").font(.caption)
                    Text(s.next.map { "→ \($0)" } ?? "Sesión completada").font(.caption2).lineLimit(1)
                } else {
                    Text("ChamaFit").font(.headline).widgetAccentable()
                    Text("Abre la app en el iPhone").font(.caption2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            if resting, let end = s?.restEnd {
                Text(timerInterval: entry.date...end, countsDown: true)
            } else {
                Text("\(s?.done ?? 0)/\(s?.total ?? 0) series")
            }
        }
    }
}
