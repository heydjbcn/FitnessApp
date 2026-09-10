//
//  RestLiveActivity.swift
//  ChamaFitWidgets
//
//  La cuenta atrás del descanso fuera de la app: pantalla bloqueada, Dynamic
//  Island y, desde watchOS 11, el Smart Stack del Apple Watch al levantar la
//  muñeca. La cuenta corre sola con Text(timerInterval:), sin actualizaciones.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            LockScreenView(context: context)
                .activityBackgroundTint(WidgetStyle.bg.opacity(0.85))
                .activitySystemActionForegroundColor(WidgetStyle.ink)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(WidgetStyle.gradient(context.attributes.accent1, context.attributes.accent2))
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(context, size: 30)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.state.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(WidgetStyle.mute)
                            .lineLimit(1)
                        progressBar(context)
                        HStack(spacing: 8) {
                            extendButton(context)
                            stopButton(context)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(WidgetStyle.gradient(context.attributes.accent1, context.attributes.accent2))
            } compactTrailing: {
                countdown(context, size: 14)
                    .frame(width: 44)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(WidgetStyle.gradient(context.attributes.accent1, context.attributes.accent2))
            }
            .keylineTint(WidgetStyle.color(context.attributes.accent1))
        }
        .supplementalActivityFamilies([.small])
    }

    // MARK: - Piezas

    private func countdown(_ context: ActivityViewContext<RestActivityAttributes>, size: CGFloat) -> some View {
        Group {
            if context.state.finished {
                Text("¡Ya!")
            } else {
                Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
            }
        }
        .font(.system(size: size, weight: .bold, design: .rounded))
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
        .foregroundStyle(WidgetStyle.gradient(context.attributes.accent1, context.attributes.accent2, horizontal: true))
    }

    private func progressBar(_ context: ActivityViewContext<RestActivityAttributes>) -> some View {
        ProgressView(timerInterval: context.state.startDate...context.state.endDate, countsDown: true, label: { EmptyView() }, currentValueLabel: { EmptyView() })
            .progressViewStyle(.linear)
            .tint(WidgetStyle.color(context.attributes.accent2))
            .frame(height: 6)
    }

    private func extendButton(_ context: ActivityViewContext<RestActivityAttributes>) -> some View {
        Button(intent: ExtendRestIntent()) {
            Text("+30 s")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(WidgetStyle.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Capsule().fill(WidgetStyle.soft))
        }
        .buttonStyle(.plain)
    }

    private func stopButton(_ context: ActivityViewContext<RestActivityAttributes>) -> some View {
        Button(intent: StopRestIntent()) {
            Text("Parar")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(WidgetStyle.onAccent(context.attributes.onAccentDark))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Capsule().fill(WidgetStyle.gradient(context.attributes.accent1, context.attributes.accent2, horizontal: true)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pantalla bloqueada y Apple Watch

private struct LockScreenView: View {
    let context: ActivityViewContext<RestActivityAttributes>
    @Environment(\.activityFamily) private var family

    var body: some View {
        switch family {
        case .small: watchView
        default: phoneView
        }
    }

    /// Smart Stack del Apple Watch: cifra grande, qué toca después y la barra.
    private var watchView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("DESCANSO")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(WidgetStyle.mute)
                Spacer()
                countdownText(size: 26)
            }
            Text(context.state.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(WidgetStyle.ink)
                .lineLimit(1)
            ProgressView(timerInterval: context.state.startDate...context.state.endDate, countsDown: true,
                         label: { EmptyView() }, currentValueLabel: { EmptyView() })
                .progressViewStyle(.linear)
                .tint(WidgetStyle.color(context.attributes.accent2))
        }
        .padding(.horizontal, 4)
    }

    private var phoneView: some View {
        HStack(spacing: 14) {
            countdownText(size: 34)
                .frame(minWidth: 96, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text("DESCANSO · \(context.attributes.sessionName.uppercased())")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(WidgetStyle.mute)
                    .lineLimit(1)
                Text(context.state.finished ? "Descanso terminado" : context.state.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(WidgetStyle.ink)
                    .lineLimit(1)
                ProgressView(timerInterval: context.state.startDate...context.state.endDate, countsDown: true,
                             label: { EmptyView() }, currentValueLabel: { EmptyView() })
                    .progressViewStyle(.linear)
                    .tint(WidgetStyle.color(context.attributes.accent2))
                    .padding(.top, 4)
            }
            if !context.state.finished {
                VStack(spacing: 6) {
                    Button(intent: ExtendRestIntent()) {
                        Text("+30 s")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(WidgetStyle.ink)
                            .frame(width: 60, height: 30)
                            .background(Capsule().fill(WidgetStyle.soft))
                    }
                    .buttonStyle(.plain)
                    Button(intent: StopRestIntent()) {
                        Text("Parar")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(WidgetStyle.onAccent(context.attributes.onAccentDark))
                            .frame(width: 60, height: 30)
                            .background(Capsule().fill(WidgetStyle.gradient(context.attributes.accent1, context.attributes.accent2, horizontal: true)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private func countdownText(size: CGFloat) -> some View {
        Group {
            if context.state.finished {
                Text("¡Ya!")
            } else {
                Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
            }
        }
        .font(.system(size: size, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(WidgetStyle.gradient(context.attributes.accent1, context.attributes.accent2, horizontal: true))
    }
}
