import WidgetKit
import SwiftUI

// Solo importar ActivityKit si está disponible
#if canImport(ActivityKit) && !os(macOS)
import ActivityKit

// Definición de TimerActivityAttributes para el widget
@available(iOS 16.1, *)
struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: Int
        var totalTime: Int
        var isActive: Bool
    }
    
    var exerciseName: String
}

// Widget principal
@available(iOS 16.1, *)
struct FitnessAppWidget: Widget {
    let kind: String = "FitnessAppWidget"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock Screen
            LockScreenTimerView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("⏸️ \(context.attributes.exerciseName)")
                        .font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatTime(TimeInterval(context.state.timeRemaining)))
                        .font(.caption.bold())
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: progressValue(for: context))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
            } compactLeading: {
                Text("⏸️")
            } compactTrailing: {
                Text(formatTimeCompact(TimeInterval(context.state.timeRemaining)))
                    .font(.caption.bold())
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

// Helper functions
@available(iOS 16.1, *)
func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

@available(iOS 16.1, *)
func formatTimeCompact(_ time: TimeInterval) -> String {
    let seconds = Int(time)
    return seconds > 60 ? "\(seconds/60):\(String(format: "%02d", seconds%60))" : "\(seconds)s"
}

@available(iOS 16.1, *)
func progressValue(for context: ActivityViewContext<TimerActivityAttributes>) -> Double {
    let elapsed = Double(context.state.totalTime - context.state.timeRemaining)
    let total = Double(context.state.totalTime)
    return total > 0 ? elapsed / total : 0
}

@available(iOS 16.1, *)
struct LockScreenTimerView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        HStack {
            Text("⏸️")
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(context.attributes.exerciseName)
                    .font(.headline)
                Text(formatTime(TimeInterval(context.state.timeRemaining)))
                    .font(.title.bold())
                    .monospacedDigit()
            }
            
            Spacer()
        }
        .padding()
    }
}

#endif
