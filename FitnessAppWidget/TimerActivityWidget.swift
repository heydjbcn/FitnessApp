//
//  TimerActivityWidget.swift
//  FitnessAppWidgetExtension
//
//  Created by Jordi Mauri on 24/7/25.
//

import SwiftUI
import WidgetKit

// Solo importar ActivityKit si está disponible
#if canImport(ActivityKit)
import ActivityKit

// MARK: - Timer Type (copiado desde el target principal)
enum TimerType: String, CaseIterable, Codable, Hashable {
    case rest = "rest"
    case work = "work"
    case warmup = "warmup"
    case cooldown = "cooldown"
    
    var displayName: String {
        switch self {
        case .rest:
            return "Descanso"
        case .work:
            return "Trabajo"
        case .warmup:
            return "Calentamiento"
        case .cooldown:
            return "Enfriamiento"
        }
    }
    
    var emoji: String {
        switch self {
        case .rest:
            return "⏸️"
        case .work:
            return "💪"
        case .warmup:
            return "🔥"
        case .cooldown:
            return "❄️"
        }
    }
}

// MARK: - Timer Activity Attributes (copiado desde el target principal)
@available(iOS 16.1, *)
@available(macOS, unavailable)
struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingTime: TimeInterval
        var isRunning: Bool
        var exerciseName: String
        var setNumber: Int
        var totalSets: Int
        
        public init(
            remainingTime: TimeInterval,
            isRunning: Bool = true,
            exerciseName: String = "",
            setNumber: Int = 0,
            totalSets: Int = 0
        ) {
            self.remainingTime = remainingTime
            self.isRunning = isRunning
            self.exerciseName = exerciseName
            self.setNumber = setNumber
            self.totalSets = totalSets
        }
    }
    
    var timerType: TimerType
    var initialDuration: TimeInterval
    var startTime: Date
    
    public init(
        timerType: TimerType,
        initialDuration: TimeInterval,
        startTime: Date = Date()
    ) {
        self.timerType = timerType
        self.initialDuration = initialDuration
        self.startTime = startTime
    }
}

// MARK: - Timer Live Activity Widget
@available(iOS 16.1, *)
@available(macOS, unavailable)
struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Vista del Lock Screen
            LockScreenTimerView(context: context)
        } dynamicIsland: { context in
            // Vista de la Dynamic Island
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Text(context.attributes.timerType.emoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.timerType.displayName)
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                            
                            if !context.state.exerciseName.isEmpty {
                                Text(context.state.exerciseName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatTime(context.state.remainingTime))
                            .font(.title2.bold())
                            .monospacedDigit()
                        
                        if context.state.totalSets > 0 {
                            Text("Serie \(context.state.setNumber)/\(context.state.totalSets)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        ProgressView(value: progressValue(for: context))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        
                        HStack {
                            Text("Tiempo restante")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatTime(context.state.remainingTime))
                                .font(.caption.bold())
                                .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                Text(context.attributes.timerType.emoji)
            } compactTrailing: {
                Text(formatTimeCompact(context.state.remainingTime))
                    .font(.caption.bold())
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

// MARK: - Helper Views and Functions
@available(iOS 16.1, *)
@available(macOS, unavailable)
struct LockScreenTimerView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(context.attributes.timerType.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.timerType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !context.state.exerciseName.isEmpty {
                        Text(context.state.exerciseName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(context.state.remainingTime))
                        .font(.title.bold())
                        .monospacedDigit()
                    
                    if context.state.totalSets > 0 {
                        Text("Serie \(context.state.setNumber)/\(context.state.totalSets)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            ProgressView(value: progressValue(for: context))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding()
        .background(Color.clear)
    }
}

// Helper functions
func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

func formatTimeCompact(_ time: TimeInterval) -> String {
    let seconds = Int(time)
    if seconds > 60 {
        return "\(seconds/60):\(String(format: "%02d", seconds%60))"
    } else {
        return "\(seconds)s"
    }
}

@available(iOS 16.1, *)
@available(macOS, unavailable)
@available(iOS 16.1, *)
@available(macOS, unavailable)
func progressValue(for context: ActivityViewContext<TimerActivityAttributes>) -> Double {
    let elapsed = context.attributes.initialDuration - context.state.remainingTime
    return max(0, min(1, elapsed / context.attributes.initialDuration))
}

#endif
