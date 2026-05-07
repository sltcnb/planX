import Foundation
import SwiftData

@MainActor
class DependencyService {
    static let shared = DependencyService()
    
    func addDependency(from predecessor: TaskItem, to successor: TaskItem, type: String = "blocks", context: ModelContext) {
        guard predecessor.id != successor.id else { return }
        
        let dependency = TaskDependency(relationshipType: type, predecessor: predecessor, successor: successor)
        
        predecessor.dependencies.append(dependency)
        successor.dependencies.append(dependency)
        
        logActivity(for: predecessor, action: "dependency_added", description: "Added dependency", context: context)
        logActivity(for: successor, action: "dependency_added", description: "Added dependency", context: context)
        
        try? context.save()
    }
    
    func removeDependency(_ dependency: TaskDependency, context: ModelContext) {
        context.delete(dependency)
        try? context.save()
    }
    
    private func logActivity(for task: TaskItem, action: String, description: String, context: ModelContext) {
        let log = ActivityLog(action: action, activityDescription: description, userName: "Nathan BUISSON")
        log.task = task
        task.activityLogs.append(log)
    }
}
