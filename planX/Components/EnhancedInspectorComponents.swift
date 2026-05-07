import SwiftUI
import SwiftData

struct RecurrencePickerView: View {
    @State private var frequency: String = "weekly"
    @State private var interval: Int = 1
    @State private var endDate: Date?
    @State private var endOption: EndOption = .never
    
    let rule: RecurrenceRule?
    let onSave: (String, Int, Date?) -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Repeat")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel") {
                    // Dismiss
                }
                
                Button("Save") {
                    var finalEndDate: Date? = nil
                    if endOption == .onDate, let endDate = endDate {
                        finalEndDate = endDate
                    }
                    onSave(frequency, interval, finalEndDate)
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
            
            Divider()
            
            Form {
                Picker("Repeat", selection: $frequency) {
                    Text("Daily").tag("daily")
                    Text("Weekly").tag("weekly")
                    Text("Monthly").tag("monthly")
                    Text("Yearly").tag("yearly")
                }
                
                Stepper("Every \(interval) \(frequency == "daily" ? "day" : frequency == "weekly" ? "week" : frequency == "monthly" ? "month" : "year")", value: $interval, in: 1...100)
                
                Picker("End", selection: $endOption) {
                    Text("Never").tag(EndOption.never)
                    Text("On date").tag(EndOption.onDate)
                    Text("After").tag(EndOption.after)
                }
                
                if endOption == .onDate {
                    DatePicker("End date", selection: Binding(
                        get: { endDate ?? Date() },
                        set: { endDate = $0 }
                    ), displayedComponents: .date)
                }
            }
            .formStyle(.grouped)
            
            if rule != nil {
                Divider()
                
                Button("Remove Recurrence", role: .destructive) {
                    onRemove()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 400, height: 350)
        .onAppear {
            if let rule = rule {
                frequency = rule.frequency
                interval = rule.interval
                endDate = rule.endDate
                if endDate != nil {
                    endOption = .onDate
                }
            } else {
                endDate = Date()
            }
        }
    }
    
    enum EndOption {
        case never
        case onDate
        case after
    }
}

struct DependencyRowView: View {
    let dependency: TaskDependency
    let task: TaskItem
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack {
            Image(systemName: dependency.relationshipType == "blocks" ? "arrow.right" : "arrow.left")
                .foregroundColor(.secondary)
            
            Text(dependency.relationshipType == "blocks" ? 
                 (dependency.successor?.title ?? "Unknown") : 
                 (dependency.predecessor?.title ?? "Unknown"))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                DependencyService.shared.removeDependency(dependency, context: modelContext)
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct ActivityLogRowView: View {
    let log: ActivityLog
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconForAction(log.action))
                .foregroundColor(.secondary)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.activityDescription)
                    .font(.caption)
                
                Text(formatDate(log.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func iconForAction(_ action: String) -> String {
        switch action {
        case "created": return "plus.circle"
        case "updated": return "pencil"
        case "completed": return "checkmark.circle"
        case "deleted": return "trash"
        case "comment_added": return "bubble.left"
        case "attachment_added": return "paperclip"
        case "time_started": return "timer"
        case "time_stopped": return "stopwatch"
        default: return "clock"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CommentRowView: View {
    let comment: Comment
    let onUpdate: (String) -> Void
    let onDelete: () -> Void
    
    @State private var isEditing: Bool = false
    @State private var editText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(comment.userName ?? "Unknown")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(formatDate(comment.createdAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if comment.isEdited {
                            Text("(edited)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Menu {
                            Button("Edit") {
                                editText = comment.content
                                isEditing = true
                            }
                            
                            Button("Delete", role: .destructive) {
                                onDelete()
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if isEditing {
                        TextEditor(text: $editText)
                            .frame(minHeight: 60)
                            .padding(8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        
                        HStack {
                            Button("Cancel") {
                                isEditing = false
                            }
                            
                            Button("Save") {
                                onUpdate(editText)
                                isEditing = false
                            }
                            .keyboardShortcut(.return, modifiers: .command)
                        }
                    } else {
                        Text(comment.content)
                            .font(.body)
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.05))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct TimeEntryRowView: View {
    let entry: TimeEntry
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.entryDescription ?? "No description")
                    .font(.caption)
                
                Text(formatDate(entry.startTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(entry.formattedDuration)
                .font(.caption)
                .monospacedDigit()
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ManualTimeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    @State private var description: String = ""
    
    let onSave: (TimeInterval, String?) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Add Time Entry")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Save") {
                    let duration = TimeInterval(hours * 3600 + minutes * 60)
                    onSave(duration, description.isEmpty ? nil : description)
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
            
            Divider()
            
            Form {
                HStack {
                    Stepper("Hours: \(hours)", value: $hours, in: 0...23)
                    Stepper("Minutes: \(minutes)", value: $minutes, in: 0...59, step: 15)
                }
                
                TextField("Description (optional)", text: $description)
            }
            .formStyle(.grouped)
        }
        .padding(20)
        .frame(width: 400)
    }
}

struct DependencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TaskItem]
    @State private var selectedTask: TaskItem?
    @State private var relationshipType: String = "blocks"

    let task: TaskItem
    let onSave: (TaskItem, String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Add Dependency")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Add") {
                    if let selectedTask = selectedTask {
                        onSave(selectedTask, relationshipType)
                        dismiss()
                    }
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
            
            Divider()
            
            Form {
                Picker("Relationship", selection: $relationshipType) {
                    Text("Blocks").tag("blocks")
                    Text("Blocked by").tag("blocked_by")
                    Text("Related").tag("related")
                }
                
                Section("Select Task") {
                    List(selection: $selectedTask) {
                        ForEach(getAvailableTasks(), id: \.id) { task in
                            Text(task.title)
                                .tag(task)
                        }
                    }
                    .frame(height: 200)
                }
            }
            .formStyle(.grouped)
        }
        .padding(20)
        .frame(width: 450, height: 400)
    }
    
    private func getAvailableTasks() -> [TaskItem] {
        allTasks.filter { $0.id != task.id }
    }
}
