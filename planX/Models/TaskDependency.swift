import Foundation
import SwiftData

@Model
final class TaskDependency {
    var id: UUID
    var relationshipType: String // "blocks", "related", "enables", "duplicate"
    
    var createdAt: Date
    
    @Relationship(deleteRule: .nullify)
    var predecessor: TaskItem?
    
    @Relationship(deleteRule: .nullify)
    var successor: TaskItem?
    
    init(id: UUID = UUID(), relationshipType: String = "blocks", predecessor: TaskItem? = nil, successor: TaskItem? = nil) {
        self.id = id
        self.relationshipType = relationshipType
        self.predecessor = predecessor
        self.successor = successor
        self.createdAt = Date()
    }
}
