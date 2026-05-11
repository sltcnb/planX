import SwiftUI
import SwiftData

struct planXBoardView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var selectedTask: TaskItem?
    @Environment(\.modelContext) private var modelContext

    private var filteredTasks: [TaskItem] { viewModel.getFilteredTasks() }

    private var notStartedTasks: [TaskItem] {
        filteredTasks.filter { $0.statusValue == .notStarted && !$0.isCompleted }
    }
    private var inProgressTasks: [TaskItem] {
        filteredTasks.filter { $0.statusValue == .inProgress }
    }
    private var waitingTasks: [TaskItem] {
        filteredTasks.filter { $0.statusValue == .waiting }
    }
    private var doneTasks: [TaskItem] {
        filteredTasks.filter { $0.statusValue == .done }
    }

    var body: some View {
        GeometryReader { geo in
            let padding: CGFloat = 16
            let spacing: CGFloat = 12
            let cols: CGFloat = 4
            let colWidth = max(220, (geo.size.width - padding * 2 - spacing * (cols - 1)) / cols)

            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                HStack(alignment: .top, spacing: spacing) {
                    BucketView(title: "To Do", icon: "circle", color: .gray,
                               targetStatus: .notStarted, tasks: notStartedTasks,
                               selectedTask: $selectedTask, viewModel: viewModel,
                               modelContext: modelContext)
                        .frame(width: colWidth)

                    BucketView(title: "In Progress", icon: "arrow.triangle.2.circlepath", color: .blue,
                               targetStatus: .inProgress, tasks: inProgressTasks,
                               selectedTask: $selectedTask, viewModel: viewModel,
                               modelContext: modelContext)
                        .frame(width: colWidth)

                    BucketView(title: "Waiting", icon: "pause.circle", color: .orange,
                               targetStatus: .waiting, tasks: waitingTasks,
                               selectedTask: $selectedTask, viewModel: viewModel,
                               modelContext: modelContext)
                        .frame(width: colWidth)

                    BucketView(title: "Done", icon: "checkmark.circle.fill", color: .green,
                               targetStatus: .done, tasks: doneTasks,
                               selectedTask: $selectedTask, viewModel: viewModel,
                               modelContext: modelContext)
                        .frame(width: colWidth)
                }
                .padding(padding)
                .frame(minHeight: geo.size.height - padding * 2, alignment: .top)
            }
        }
    }
}

struct BucketView: View {
    let title: String
    let icon: String
    let color: Color
    let targetStatus: TaskStatus
    let tasks: [TaskItem]
    @Binding var selectedTask: TaskItem?
    @ObservedObject var viewModel: AppViewModel
    let modelContext: ModelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.headline)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(tasks, id: \.id) { task in
                    taskCard(task)
                }

                if tasks.isEmpty {
                    Text("Drop tasks here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                }
            }

            Menu {
                Button("Quick Add") { viewModel.showQuickAdd = true }
                Button("Full Form") { createTask(status: targetStatus) }
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add task")
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(12)
        .onDrop(of: [.text], isTargeted: nil) { providers in
            let snapshot = viewModel.tasks
            providers.forEach { provider in
                provider.loadItem(forTypeIdentifier: "public.utf8-plain-text", options: nil) { item, _ in
                    if let data = item as? Data,
                       let uuidString = String(data: data, encoding: .utf8),
                       let taskUUID = UUID(uuidString: uuidString),
                       let task = snapshot.first(where: { $0.id == taskUUID }) {
                        DispatchQueue.main.async { updateTaskStatus(task, to: targetStatus) }
                    }
                }
            }
            return true
        }
    }

    @ViewBuilder
    private func taskCard(_ task: TaskItem) -> some View {
        planXTaskCardView(
            task: task,
            isSelected: selectedTask?.modelContext != nil && selectedTask?.id == task.id,
            isSelectMode: viewModel.isSelectMode,
            isCheckSelected: viewModel.selectedTaskIDs.contains(task.id),
            onTap: {
                if viewModel.isSelectMode {
                    if viewModel.selectedTaskIDs.contains(task.id) {
                        viewModel.selectedTaskIDs.remove(task.id)
                    } else {
                        viewModel.selectedTaskIDs.insert(task.id)
                    }
                } else {
                    selectedTask = task
                }
            },
            onToggleComplete: { updateTaskStatus(task, to: task.isCompleted ? .notStarted : .done) },
            onDelete: {
                if selectedTask?.id == task.id { selectedTask = nil }
                viewModel.tasks.removeAll { $0.id == task.id }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    let tid = task.id
                    if let allDeps = try? modelContext.fetch(FetchDescriptor<TaskDependency>()) {
                        for dep in allDeps where dep.predecessor?.id == tid || dep.successor?.id == tid {
                            modelContext.delete(dep)
                        }
                    }
                    modelContext.delete(task)
                    try? modelContext.save()
                    viewModel.refresh()
                }
            },
            modelContext: modelContext
        )
        .onDrag { NSItemProvider(object: NSString(string: task.id.uuidString)) }
    }

    private func createTask(status: TaskStatus) {
        let task = TaskItem(title: "")
        task.statusValue = status
        modelContext.insert(task)
        try? modelContext.save()
        viewModel.refresh()
        selectedTask = task
    }

    private func updateTaskStatus(_ task: TaskItem, to status: TaskStatus) {
        task.statusValue = status
        task.updatedAt = Date()
        task.completedAt = status == .done ? Date() : nil
        try? modelContext.save()
        viewModel.refresh()
    }
}

struct planXTaskCardView: View {
    let task: TaskItem
    let isSelected: Bool
    let isSelectMode: Bool
    let isCheckSelected: Bool
    let onTap: () -> Void
    let onToggleComplete: () -> Void
    let onDelete: () -> Void
    let modelContext: ModelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                if isSelectMode {
                    Image(systemName: isCheckSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCheckSelected ? .accentColor : .secondary)
                        .font(.system(size: 14))
                } else {
                    Button(action: onToggleComplete) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }

                Text(task.title)
                    .font(.body.weight(.medium))
                    .lineLimit(2)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                Spacer(minLength: 0)
            }

            if task.hasSubtasks {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(task.subtasks.sorted { $0.orderIndex < $1.orderIndex }.prefix(4)), id: \.id) { subtask in
                        Button(action: {
                            subtask.isCompleted.toggle()
                            subtask.updatedAt = Date()
                            try? modelContext.save()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 10))
                                    .foregroundColor(subtask.isCompleted ? .green : .secondary)
                                Text(subtask.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundColor(subtask.isCompleted ? .secondary : .primary)
                                    .strikethrough(subtask.isCompleted)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    if task.totalSubtaskCount > 4 {
                        Text("+\(task.totalSubtaskCount - 4) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 20)
            }

            if task.showNotesOnKanban && !task.notes.isEmpty {
                Text(task.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                    .padding(.leading, 20)
            }

            if let activeEntry = task.timeEntries.first(where: { $0.endTime == nil }) {
                TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                    Label(elapsedString(from: activeEntry.startTime), systemImage: "timer")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(4)
                }
                .padding(.leading, 20)
            }

            HStack(spacing: 6) {
                if let dueDate = task.dueDate {
                    Label(formatDate(dueDate), systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(task.isOverdue ? Color.red.opacity(0.15) : Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
                priorityBadge
                Spacer(minLength: 0)
                if let project = task.project {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: project.color ?? "blue"))
                            .frame(width: 6, height: 6)
                        Text(project.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.leading, 20)
        }
        .padding(10)
        .background(isCheckSelected ? Color.accentColor.opacity(0.15) : (isSelected ? Color.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isCheckSelected ? Color.accentColor : (isSelected ? Color.accentColor : Color.clear), lineWidth: 2))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button(task.isCompleted ? "Mark Incomplete" : "Mark Complete") {
                onToggleComplete()
            }
            Divider()
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }

    @ViewBuilder private var priorityBadge: some View {
        let (label, color): (String, Color) = {
            switch task.priorityValue {
            case .high:   return ("High", .red)
            case .medium: return ("Medium", .orange)
            case .low:    return ("Low", .secondary)
            }
        }()
        Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }

    private func elapsedString(from start: Date) -> String {
        let s = Int(Date().timeIntervalSince(start))
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%02d:%02d", m, sec)
    }

    private func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }
}
