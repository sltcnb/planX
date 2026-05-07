import Foundation
import SwiftData

@MainActor
class TaskDetailViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var notes: String = ""
    @Published var dueDate: Date?
    @Published var startDate: Date?
    @Published var priority: Priority = .medium
    @Published var status: TaskStatus = .notStarted
    @Published var selectedProject: Project?
    @Published var selectedTags: [Tag] = []
    
    @Published var subtasks: [Subtask] = []
    
    @Published var allProjects: [Project] = []
    @Published var allTags: [Tag] = []
    
    var task: TaskItem?
    var modelContext: ModelContext?
    
    func loadTask(_ task: TaskItem) {
        self.task = task
        self.title = task.title
        self.notes = task.notes
        self.dueDate = task.dueDate
        self.startDate = task.startDate
        self.priority = task.priorityValue
        self.status = task.statusValue
        self.selectedProject = task.project
        self.selectedTags = task.tags
        self.subtasks = task.subtasks.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadProjects()
        loadTags()
    }
    
    func loadProjects() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.name)])
        allProjects = (try? context.fetch(descriptor)) ?? []
    }
    
    func loadTags() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        allTags = (try? context.fetch(descriptor)) ?? []
    }
    
    func save() {
        guard let task = task, let context = modelContext else { return }
        
        task.title = title
        task.notes = notes
        task.dueDate = dueDate
        task.startDate = startDate
        task.priorityValue = priority
        task.statusValue = status
        task.project = selectedProject
        task.tags = selectedTags
        task.updatedAt = Date()
        
        if task.isCompleted && task.completedAt == nil {
            task.completedAt = Date()
        }
        
        try? context.save()
    }
    
    func addSubtask(title: String, notes: String? = nil) {
        guard let task = task, let context = modelContext else { return }
        
        let orderIndex = subtasks.map { $0.orderIndex }.max() ?? -1
        let subtask = Subtask(
            title: title,
            notes: notes,
            isCompleted: false,
            dueDate: nil,
            orderIndex: orderIndex + 1
        )
        subtask.parentTask = task
        task.subtasks.append(subtask)
        subtasks.append(subtask)
        
        try? context.save()
    }
    
    func updateSubtask(_ subtask: Subtask) {
        subtask.updatedAt = Date()
        guard let context = modelContext else { return }
        try? context.save()
    }
    
    func deleteSubtask(_ subtask: Subtask) {
        guard let context = modelContext else { return }
        modelContext?.delete(subtask)
        subtasks.removeAll { $0.id == subtask.id }
        try? context.save()
    }
    
    func toggleSubtaskComplete(_ subtask: Subtask) {
        subtask.isCompleted.toggle()
        subtask.updatedAt = Date()
        guard let context = modelContext else { return }
        try? context.save()
    }
    
    func reorderSubtasks(_ subtasks: [Subtask]) {
        for (index, subtask) in subtasks.enumerated() {
            subtask.orderIndex = index
            subtask.updatedAt = Date()
        }
        self.subtasks = subtasks
        guard let context = modelContext else { return }
        try? context.save()
    }
    
    // MARK: - New Features
    
    var isTrackingTime: Bool {
        guard let task = task else { return false }
        return TimeTrackingService.shared.isTrackingTime(for: task)
    }
    
    var isCompleted: Bool {
        get { task?.isCompleted ?? false }
        set {
            task?.isCompleted = newValue
            status = newValue ? .done : .notStarted
        }
    }

    var isBlocked: Bool {
        task?.blockedByTasks.contains { !$0.isCompleted } ?? false
    }
    
    var isRecurring: Bool {
        task?.recurrenceRule != nil
    }
    
    func refresh() {
        guard let task = task else { return }
        loadTask(task)
        objectWillChange.send()
    }
    
    func addDependency(to otherTask: TaskItem, type: String) {
        guard let task = task, let context = modelContext else { return }
        DependencyService.shared.addDependency(from: task, to: otherTask, type: type, context: context)
        refresh()
    }
    
    func startTimer(description: String? = nil) {
        guard let task = task, let context = modelContext else { return }
        _ = TimeTrackingService.shared.startTracking(for: task, description: description, context: context)
        refresh()
    }
    
    func stopTimer() {
        guard let task = task, let context = modelContext else { return }
        TimeTrackingService.shared.stopTracking(for: task, context: context)
        refresh()
    }
    
    func addComment(content: String) {
        guard let task = task, let context = modelContext else { return }
        _ = CommentService.shared.addComment(to: task, content: content, userName: "Nathan BUISSON", context: context)
        refresh()
    }
    
    func addAttachment(data: Data, name: String, mimeType: String) {
        guard let task = task, let context = modelContext else { return }
        _ = AttachmentService.shared.addAttachment(to: task, data: data, name: name, mimeType: mimeType, context: context)
        refresh()
    }
    
    func setRecurrence(frequency: String, interval: Int, endDate: Date?) {
        guard let task = task, let context = modelContext else { return }
        RecurrenceService.shared.setRecurrence(for: task, frequency: frequency, interval: interval, endDate: endDate, context: context)
        refresh()
    }
    
    func removeRecurrence() {
        guard let task = task, let context = modelContext else { return }
        RecurrenceService.shared.removeRecurrence(from: task, context: context)
        refresh()
    }
    
    func completeRecurringTask() {
        guard let task = task, let context = modelContext else { return }
        RecurrenceService.shared.completeRecurringTask(task, context: context)
        refresh()
    }
    
    func addManualTime(duration: TimeInterval, description: String?) {
        guard let task = task, let context = modelContext else { return }
        TimeTrackingService.shared.addManualTimeEntry(for: task, duration: duration, description: description, context: context)
        refresh()
    }
    
    func deleteTimeEntry(_ entry: TimeEntry) {
        guard let context = modelContext else { return }
        TimeTrackingService.shared.deleteTimeEntry(entry, context: context)
        refresh()
    }
    
    func deleteComment(_ comment: Comment) {
        guard let context = modelContext else { return }
        CommentService.shared.deleteComment(comment, context: context)
        refresh()
    }
    
    func updateComment(_ comment: Comment, content: String) {
        guard let context = modelContext else { return }
        CommentService.shared.updateComment(comment, content: content, context: context)
        refresh()
    }
}
