import Foundation
import SwiftData

@Model
final class Subtask {
    var id: UUID
    var title: String
    var notes: String?
    var isCompleted: Bool
    var dueDate: Date?
    var orderIndex: Int
    
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .nullify)
    var parentTask: TaskItem?
    
    init(id: UUID = UUID(), title: String, notes: String? = nil, isCompleted: Bool = false, dueDate: Date? = nil, orderIndex: Int = 0) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.orderIndex = orderIndex
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
