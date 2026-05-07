import Foundation
import SwiftData

@MainActor
class TimeTrackingService {
    static let shared = TimeTrackingService()
    
    @Published var activeEntries: [UUID: TimeEntry] = [:]
    
    func startTracking(for task: TaskItem, description: String? = nil, context: ModelContext) -> TimeEntry {
        let entry = TimeEntry(
            startTime: Date(),
            entryDescription: description
        )
        entry.task = task
        task.timeEntries.append(entry)
        
        activeEntries[task.id] = entry
        
        logActivity(for: task, action: "time_started", description: "Started time tracking", context: context)
        try? context.save()
        
        return entry
    }
    
    func stopTracking(for task: TaskItem, context: ModelContext) {
        guard let entry = activeEntries[task.id] else { return }
        
        entry.endTime = Date()
        entry.duration = entry.endTime!.timeIntervalSince(entry.startTime)
        
        activeEntries.removeValue(forKey: task.id)
        
        logActivity(for: task, action: "time_stopped", description: "Stopped time tracking", context: context)
        try? context.save()
    }
    
    func isTrackingTime(for task: TaskItem) -> Bool {
        return activeEntries[task.id] != nil
    }
    
    func addManualTimeEntry(for task: TaskItem, duration: TimeInterval, date: Date = Date(), description: String? = nil, context: ModelContext) {
        let entry = TimeEntry(
            startTime: date,
            endTime: date.addingTimeInterval(duration),
            duration: duration,
            entryDescription: description
        )
        entry.task = task
        task.timeEntries.append(entry)
        
        logActivity(for: task, action: "time_added", description: "Added time entry", context: context)
        try? context.save()
    }
    
    func deleteTimeEntry(_ entry: TimeEntry, context: ModelContext) {
        context.delete(entry)
        try? context.save()
    }
    
    private func logActivity(for task: TaskItem, action: String, description: String, context: ModelContext) {
        let log = ActivityLog(action: action, activityDescription: description, userName: "Nathan BUISSON")
        log.task = task
        task.activityLogs.append(log)
    }
}
