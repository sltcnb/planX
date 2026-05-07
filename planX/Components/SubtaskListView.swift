import SwiftUI

struct SubtaskListView: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @State private var draggables: [Subtask] = []
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(viewModel.subtasks.sorted { $0.orderIndex < $1.orderIndex }, id: \.id) { subtask in
                SubtaskRowView(
                    subtask: subtask,
                    onToggle: {
                        viewModel.toggleSubtaskComplete(subtask)
                    },
                    onDelete: {
                        viewModel.deleteSubtask(subtask)
                    },
                    onUpdate: {
                        viewModel.updateSubtask(subtask)
                    }
                )
            }
            .onMove { source, destination in
                var sorted = viewModel.subtasks.sorted { $0.orderIndex < $1.orderIndex }
                sorted.move(fromOffsets: source, toOffset: destination)
                viewModel.reorderSubtasks(sorted)
            }
        }
    }
}

struct SubtaskRowView: View {
    let subtask: Subtask
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onUpdate: () -> Void
    
    @State private var isEditingTitle: Bool = false
    @State private var titleText: String = ""
    @State private var showingNotes: Bool = false
    @State private var notesText: String = ""
    @FocusState private var titleFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
                .font(.system(size: 10))
            
            Button(action: onToggle) {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(subtask.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            if isEditingTitle {
                TextField("Subtask", text: $titleText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($titleFocused)
                    .onAppear { titleFocused = true }
                    .onSubmit {
                        saveTitle()
                    }
                    .onExitCommand {
                        saveTitle()
                    }
            } else {
                Text(subtask.title)
                    .strikethrough(subtask.isCompleted)
                    .foregroundColor(subtask.isCompleted ? .secondary : .primary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        titleText = subtask.title
                        isEditingTitle = true
                    }
            }
            
            Spacer()
            
            if subtask.notes != nil && !subtask.notes!.isEmpty {
                Image(systemName: "note.text")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            if let dueDate = subtask.dueDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(formatDate(dueDate))
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(0)
            .onHover { hovering in
                // Will be shown on hover
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.clear)
        .cornerRadius(6)
        .contextMenu {
            Button("Edit") {
                titleText = subtask.title
                isEditingTitle = true
            }
            
            if subtask.notes != nil {
                Button("View Notes") {
                    notesText = subtask.notes ?? ""
                    showingNotes = true
                }
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
        .sheet(isPresented: $showingNotes) {
            VStack {
                TextEditor(text: $notesText)
                    .frame(width: 400, height: 200)
                    .padding()
                
                HStack {
                    Button("Cancel") {
                        showingNotes = false
                    }
                    
                    Button("Save") {
                        subtask.notes = notesText.isEmpty ? nil : notesText
                        onUpdate()
                        showingNotes = false
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                }
                .padding()
            }
        }
    }
    
    private func saveTitle() {
        guard isEditingTitle else { return }
        isEditingTitle = false
        
        if !titleText.isEmpty && titleText != subtask.title {
            subtask.title = titleText
            onUpdate()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}
