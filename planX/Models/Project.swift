import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var taskDescription: String?
    var color: String?
    
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .nullify, inverse: \TaskItem.project)
    var tasks: [TaskItem]?
    
    init(id: UUID = UUID(), name: String, taskDescription: String? = nil, color: String? = nil) {
        self.id = id
        self.name = name
        self.taskDescription = taskDescription
        self.color = color
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tasks = []
    }
    
    var taskCount: Int {
        tasks?.count ?? 0
    }
    
    var completedCount: Int {
        tasks?.filter { $0.status == TaskStatus.done.rawValue }.count ?? 0
    }
}
