import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleComplete: () -> Void
    let onDelete: (() -> Void)?
    
    @Environment(\.modelContext) private var modelContext
    
    init(task: TaskItem, isSelected: Bool, onTap: @escaping () -> Void, onToggleComplete: @escaping () -> Void, onDelete: (() -> Void)? = nil) {
        self.task = task
        self.isSelected = isSelected
        self.onTap = onTap
        self.onToggleComplete = onToggleComplete
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(formatDate(dueDate))
                                .font(.caption2)
                        }
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                    }
                    
                    if task.priorityValue == .high {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else if task.priorityValue == .medium {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    if let project = task.project {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(project.color ?? "blue" == "blue" ? .blue : .green)
                                .frame(width: 6, height: 6)
                            Text(project.name)
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    if !task.tags.isEmpty {
                        ForEach(task.tags.prefix(2), id: \.id) { tag in
                            Text("#\(tag.name)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            if task.hasSubtasks {
                VStack(alignment: .trailing) {
                    ProgressView(value: task.subtaskProgress)
                        .frame(width: 50)
                    Text("\(task.completedSubtaskCount)/\(task.totalSubtaskCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Delete button (visible on hover/selection)
            Button(action: deleteTask) {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isSelected ? 1 : 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button(task.isCompleted ? "Mark Incomplete" : "Mark Complete") {
                onToggleComplete()
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                deleteTask()
            }
        }
    }
    
    private func deleteTask() {
        if let onDelete = onDelete {
            onDelete()
        } else {
            modelContext.delete(task)
            try? modelContext.save()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    TaskRowView(
        task: TaskItem(title: "Sample Task", priority: .high),
        isSelected: false,
        onTap: {},
        onToggleComplete: {}
    )
    .padding()
}
