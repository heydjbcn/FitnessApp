import SwiftUI
import WidgetKit
import ActivityKit

@available(iOS 16.1, *)
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock screen/banner UI
            VStack {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.green)
                    Text("Timer de Descanso")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack {
                    Text("Tiempo restante:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(timeString(from: context.state.timeRemaining))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                ProgressView(value: Double(context.state.totalTime - context.state.timeRemaining), total: Double(context.state.totalTime))
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI (cuando se toca)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("Timer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Descanso")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(timeString(from: context.state.timeRemaining))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        ProgressView(value: Double(context.state.totalTime - context.state.timeRemaining), total: Double(context.state.totalTime))
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .frame(width: 60)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Spacer()
                        Text("Tiempo de descanso entre ejercicios")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            } compactLeading: {
                // Lado izquierdo compacto
                Image(systemName: "timer")
                    .foregroundColor(.green)
            } compactTrailing: {
                // Lado derecho compacto
                Text(timeString(from: context.state.timeRemaining))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            } minimal: {
                // Vista mínima
                Image(systemName: "timer")
                    .foregroundColor(.green)
            }
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
