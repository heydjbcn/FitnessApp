import SwiftUI
import ActivityKit
import Combine

@available(iOS 16.1, *)
struct TimerActivityAttributes: ActivityAttributes {
    public typealias TimerStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var timeRemaining: Int
        var totalTime: Int
        var isActive: Bool
    }
    
    var exerciseName: String
}

@available(iOS 16.1, *)
@MainActor
class LiveActivityManager: ObservableObject {
    @Published var currentActivity: Activity<TimerActivityAttributes>? = nil
    
    func startTimerActivity(exerciseName: String, totalTime: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Activities are not enabled")
            return
        }
        
        let attributes = TimerActivityAttributes(exerciseName: exerciseName)
        let contentState = TimerActivityAttributes.ContentState(
            timeRemaining: totalTime,
            totalTime: totalTime,
            isActive: true
        )
        
        do {
            currentActivity = try Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(
                    state: contentState,
                    staleDate: Date().addingTimeInterval(60)
                ),
                pushType: nil
            )
        } catch {
            print("Error starting activity: \(error)")
        }
    }
    
    func updateTimerActivity(timeRemaining: Int, totalTime: Int, isActive: Bool) {
        guard let activity = currentActivity else { return }
        
        let contentState = TimerActivityAttributes.ContentState(
            timeRemaining: timeRemaining,
            totalTime: totalTime,
            isActive: isActive
        )
        
        Task {
            await activity.update(ActivityContent(
                state: contentState,
                staleDate: Date().addingTimeInterval(60)
            ))
        }
    }
    
    func endTimerActivity() {
        guard let activity = currentActivity else { return }
        
        let contentState = TimerActivityAttributes.ContentState(
            timeRemaining: 0,
            totalTime: 0,
            isActive: false
        )
        
        Task {
            await activity.end(
                ActivityContent(state: contentState, staleDate: Date()),
                dismissalPolicy: .immediate
            )
        }
        
        currentActivity = nil
    }
}
