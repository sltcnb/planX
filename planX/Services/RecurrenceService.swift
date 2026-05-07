import Foundation
import SwiftData

@MainActor
class RecurrenceService {
    static let shared = RecurrenceService()
    
    func setRecurrence(for task: TaskItem, frequency: String, interval: Int = 1, endDate: Date? = nil, count: Int? = nil, context: ModelContext) {
        if let existingRule = task.recurrenceRule {
            existingRule.frequency = frequency
            existingRule.interval = interval
            existingRule.endDate = endDate
            existingRule.count = count
            existingRule.updatedAt = Date()
        } else {
            let rule = RecurrenceRule(frequency: frequency, interval: interval, endDate: endDate, count: count)
            rule.parentTask = task
            task.recurrenceRule = rule
        }
        
        logActivity(for: task, action: "recurrence_set", description: "Set recurrence: \(frequency)", context: context)
        try? context.save()
    }
    
    func removeRecurrence(from task: TaskItem, context: ModelContext) {
        guard let rule = task.recurrenceRule else { return }
        
        logActivity(for: task, action: "recurrence_removed", description: "Removed recurrence", context: context)
        context.delete(rule)
        try? context.save()
    }
    
    func completeRecurringTask(_ task: TaskItem, context: ModelContext) {
        guard let rule = task.recurrenceRule, let dueDate = task.dueDate else {
            task.isCompleted = true
            return
        }
        
        guard let nextDate = rule.nextOccurrence(from: dueDate) else {
            task.isCompleted = true
            return
        }
        
        let nextTask = TaskItem(
            title: task.title,
            notes: task.notes,
            dueDate: nextDate,
            priority: task.priorityValue
        )
        
        nextTask.project = task.project
        nextTask.tags = task.tags
        
        context.insert(nextTask)
        task.isCompleted = true
        
        logActivity(for: task, action: "recurrence_completed", description: "Completed recurring task", context: context)
        try? context.save()
    }
    
    private func logActivity(for task: TaskItem, action: String, description: String, context: ModelContext) {
        let log = ActivityLog(action: action, activityDescription: description, userName: "Nathan BUISSON")
        log.task = task
        task.activityLogs.append(log)
    }
}
