import Foundation
import SwiftData

@Model
final class ActivityLog {
    var id: UUID
    var action: String // created, updated, completed, deleted, comment_added
    var activityDescription: String
    var timestamp: Date
    
    var userId: String?
    var userName: String?
    
    @Relationship(deleteRule: .nullify)
    var task: TaskItem?
    
    init(id: UUID = UUID(), action: String, activityDescription: String, userId: String? = nil, userName: String? = nil) {
        self.id = id
        self.action = action
        self.activityDescription = activityDescription
        self.timestamp = Date()
        self.userId = userId
        self.userName = userName
    }
}
