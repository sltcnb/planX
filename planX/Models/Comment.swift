import Foundation
import SwiftData

@Model
final class Comment {
    var id: UUID
    var content: String
    var isEdited: Bool
    
    var createdAt: Date
    var updatedAt: Date
    
    var userId: String?
    var userName: String?
    
    @Relationship(deleteRule: .nullify)
    var task: TaskItem?
    
    init(id: UUID = UUID(), content: String, userId: String? = nil, userName: String? = nil) {
        self.id = id
        self.content = content
        self.isEdited = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.userId = userId
        self.userName = userName
    }
}
