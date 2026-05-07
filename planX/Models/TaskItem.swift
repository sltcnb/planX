import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var notes: String
    var dueDate: Date?
    var startDate: Date?
    var priority: Int
    var status: Int
    
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    
    @Relationship(deleteRule: .nullify)
    var project: Project?
    
    @Relationship(deleteRule: .cascade, inverse: \Subtask.parentTask)
    var subtasks: [Subtask]
    
    @Relationship(deleteRule: .nullify)
    var tags: [Tag]

    @Relationship(deleteRule: .cascade, inverse: \RecurrenceRule.parentTask)
    var recurrenceRule: RecurrenceRule?

    @Relationship(deleteRule: .cascade, inverse: \ActivityLog.task)
    var activityLogs: [ActivityLog]

    @Relationship(deleteRule: .cascade, inverse: \TimeEntry.task)
    var timeEntries: [TimeEntry]

    @Relationship(deleteRule: .cascade, inverse: \Comment.task)
    var comments: [Comment]

    @Relationship(deleteRule: .cascade, inverse: \Attachment.task)
    var attachments: [Attachment]

    @Relationship(deleteRule: .nullify)
    var dependencies: [TaskDependency]

    var sortIndex: Int
    var customSortOrder: Int
    var showNotesOnKanban: Bool = false

    init(id: UUID = UUID(), title: String, notes: String = "", dueDate: Date? = nil, startDate: Date? = nil, priority: Priority = .medium, status: TaskStatus = .notStarted) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.startDate = startDate
        self.priority = priority.rawValue
        self.status = status.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        self.subtasks = []
        self.tags = []
        self.recurrenceRule = nil
        self.activityLogs = []
        self.timeEntries = []
        self.comments = []
        self.attachments = []
        self.dependencies = []
        self.sortIndex = 0
        self.customSortOrder = 0
    }
    
    var priorityValue: Priority {
        get { Priority(rawValue: priority) ?? .medium }
        set { priority = newValue.rawValue }
    }
    
    var statusValue: TaskStatus {
        get { TaskStatus(rawValue: status) ?? .notStarted }
        set { status = newValue.rawValue }
    }
    
    var isCompleted: Bool {
        get { statusValue == .done }
        set {
            if newValue {
                statusValue = .done
                completedAt = Date()
            } else {
                statusValue = .notStarted
                completedAt = nil
            }
        }
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date() && !Calendar.current.isDateInToday(dueDate)
    }
    
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    var isDueTomorrow: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }
    
    var isDueThisWeek: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    var hasSubtasks: Bool {
        !subtasks.isEmpty
    }
    
    var completedSubtaskCount: Int {
        subtasks.filter { $0.isCompleted }.count
    }
    
    var totalSubtaskCount: Int {
        subtasks.count
    }
    
    var subtaskProgress: Double {
        guard totalSubtaskCount > 0 else { return 0 }
        return Double(completedSubtaskCount) / Double(totalSubtaskCount)
    }

    var formattedTotalTime: String {
        let total = timeEntries.reduce(0.0) { $0 + $1.duration }
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    var blockedByTasks: [TaskItem] {
        dependencies.filter { $0.successor?.id == id }.compactMap { $0.predecessor }
    }

    var blockingTasks: [TaskItem] {
        dependencies.filter { $0.predecessor?.id == id }.compactMap { $0.successor }
    }
}
