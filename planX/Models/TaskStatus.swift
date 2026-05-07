import Foundation

enum TaskStatus: Int, Codable, CaseIterable {
    case notStarted = 0
    case inProgress = 1
    case waiting = 2
    case done = 3
    
    var name: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .waiting: return "Waiting"
        case .done: return "Done"
        }
    }
    
    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .waiting: return "pause.circle"
        case .done: return "checkmark.circle.fill"
        }
    }
}
