import Foundation
import Combine

struct AppNotification: Identifiable, Codable {
    var id = UUID()
    let title: String
    let message: String
    let timestamp: Date
    let type: NotificationType
    var isRead: Bool = false
    
    enum NotificationType: String, Codable, CaseIterable {
        case workoutReminder = "workout_reminder"
        case restTimer = "rest_timer"
        case achievement = "achievement"
        case general = "general"
        
        var icon: String {
            switch self {
            case .workoutReminder: return "alarm.fill"
            case .restTimer: return "timer"
            case .achievement: return "trophy.fill"
            case .general: return "bell.fill"
            }
        }
        
        var color: String {
            switch self {
            case .workoutReminder: return "blue"
            case .restTimer: return "orange"
            case .achievement: return "yellow"
            case .general: return "gray"
            }
        }
    }
}
