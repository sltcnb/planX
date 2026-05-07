import Foundation
import SwiftData

@MainActor
class TaskService {
    static let shared = TaskService()

    // MARK: - Tasks

    func createTask(title: String, notes: String = "", dueDate: Date? = nil, priority: Priority = .medium, project: Project? = nil, tags: [Tag] = [], context: ModelContext) -> TaskItem {
        let task = TaskItem(title: title, notes: notes, dueDate: dueDate, priority: priority, status: .notStarted)
        task.project = project
        task.tags = tags
        context.insert(task)
        try? context.save()
        return task
    }

    func updateTask(_ task: TaskItem, context: ModelContext) {
        task.updatedAt = Date()
        try? context.save()
    }

    func deleteTask(_ task: TaskItem, context: ModelContext) {
        context.delete(task)
        try? context.save()
    }

    func toggleComplete(_ task: TaskItem, context: ModelContext) {
        task.isCompleted.toggle()
        task.updatedAt = Date()
        try? context.save()
    }

    // MARK: - Subtasks

    func createSubtask(title: String, for task: TaskItem, notes: String? = nil, dueDate: Date? = nil, context: ModelContext) -> Subtask {
        let orderIndex = (task.subtasks.map { $0.orderIndex }.max() ?? -1) + 1
        let subtask = Subtask(title: title, notes: notes, isCompleted: false, dueDate: dueDate, orderIndex: orderIndex)
        subtask.parentTask = task
        task.subtasks.append(subtask)
        try? context.save()
        return subtask
    }

    func updateSubtask(_ subtask: Subtask, context: ModelContext) {
        subtask.updatedAt = Date()
        try? context.save()
    }

    func deleteSubtask(_ subtask: Subtask, context: ModelContext) {
        context.delete(subtask)
        try? context.save()
    }

    func toggleSubtaskComplete(_ subtask: Subtask, context: ModelContext) {
        subtask.isCompleted.toggle()
        subtask.updatedAt = Date()
        try? context.save()
    }

    func reorderSubtasks(_ subtasks: [Subtask], context: ModelContext) {
        for (index, subtask) in subtasks.enumerated() {
            subtask.orderIndex = index
            subtask.updatedAt = Date()
        }
        try? context.save()
    }

    // MARK: - Projects

    func createProject(name: String, taskDescription: String? = nil, color: String? = nil, context: ModelContext) -> Project {
        let project = Project(name: name, taskDescription: taskDescription, color: color)
        context.insert(project)
        try? context.save()
        return project
    }

    func updateProject(_ project: Project, context: ModelContext) {
        project.updatedAt = Date()
        try? context.save()
    }

    func deleteProject(_ project: Project, context: ModelContext) {
        context.delete(project)
        try? context.save()
    }

    // MARK: - Tags

    func createTag(name: String, color: String = "blue", context: ModelContext) -> Tag {
        let tag = Tag(name: name, color: color)
        context.insert(tag)
        try? context.save()
        return tag
    }

    func getOrCreateTag(name: String, color: String = "blue", context: ModelContext) -> Tag {
        let all = (try? context.fetch(FetchDescriptor<Tag>())) ?? []
        if let existing = all.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return existing
        }
        return createTag(name: name, color: color, context: context)
    }

    // MARK: - Fetch

    func searchTasks(query: String, context: ModelContext) -> [TaskItem] {
        let all = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        let lower = query.lowercased()
        return all.filter { task in
            task.title.lowercased().contains(lower) ||
            task.notes.lowercased().contains(lower) ||
            task.subtasks.contains { $0.title.lowercased().contains(lower) } ||
            task.tags.contains { $0.name.lowercased().contains(lower) } ||
            (task.project?.name.lowercased().contains(lower) ?? false)
        }
    }

    func getTasksDueToday(context: ModelContext) -> [TaskItem] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let doneRaw = TaskStatus.done.rawValue
        let farPast = Date.distantPast
        let farFuture = Date.distantFuture
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                (task.dueDate ?? farPast) >= startOfDay &&
                (task.dueDate ?? farFuture) < endOfDay &&
                task.status != doneRaw
            },
            sortBy: [SortDescriptor(\.dueDate), SortDescriptor(\.priority, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func getOverdueTasks(context: ModelContext) -> [TaskItem] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let doneRaw = TaskStatus.done.rawValue
        let farFuture = Date.distantFuture
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                (task.dueDate ?? farFuture) < startOfToday && task.status != doneRaw
            },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func getUpcomingTasks(context: ModelContext) -> [TaskItem] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let endOfWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startOfToday)!
        let doneRaw = TaskStatus.done.rawValue
        let farPast = Date.distantPast
        let farFuture = Date.distantFuture
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                (task.dueDate ?? farPast) >= startOfToday &&
                (task.dueDate ?? farFuture) < endOfWeek &&
                task.status != doneRaw
            },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func getAllTasks(context: ModelContext) -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func getCompletedTasks(context: ModelContext) -> [TaskItem] {
        let all = (try? context.fetch(FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        ))) ?? []
        return all.filter { $0.isCompleted }
    }

    func getTasksForProject(_ project: Project, context: ModelContext) -> [TaskItem] {
        let projectId = project.id
        let all = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        return all
            .filter { $0.project?.id == projectId }
            .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }

    func getTasksForTag(_ tag: Tag, context: ModelContext) -> [TaskItem] {
        let tagId = tag.id
        let all = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        return all.filter { $0.tags.contains { $0.id == tagId } }
    }

    func getAllProjects(context: ModelContext) -> [Project] {
        let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func getAllTags(context: ModelContext) -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }
}
