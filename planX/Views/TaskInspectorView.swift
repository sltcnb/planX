import SwiftUI

struct TaskInspectorView: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var newSubtaskTitle: String = ""
    @State private var showingSubtaskInput: Bool = false
    @State private var newLabelName: String = ""
    @State private var showingAddLabel: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                
                Divider()
                
                statusSection
                
                Divider()
                
                labelsSection
                
                Divider()
                
                assigneeSection
                
                Divider()
                
                datesSection
                
                Divider()
                
                repeatSection
                
                Divider()
                
                bucketSection
                
                Divider()
                
                checklistSection
                
                Divider()
                
                notesSection
                
                Divider()
                
                attachmentsSection
            }
        }
        .onChange(of: viewModel.title) { viewModel.save() }
        .onChange(of: viewModel.notes) { viewModel.save() }
        .onChange(of: viewModel.dueDate) { viewModel.save() }
        .onChange(of: viewModel.priority) { viewModel.save() }
        .onChange(of: viewModel.status) { viewModel.save() }
        .onChange(of: viewModel.selectedProject?.id) { viewModel.save() }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Task title", text: $viewModel.title)
                .font(.system(size: 18, weight: .semibold))
                .textFieldStyle(.plain)
            
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.isCompleted.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(viewModel.isCompleted ? .green : .secondary)
                        Text(viewModel.isCompleted ? "Completed" : "Mark complete")
                            .foregroundColor(viewModel.isCompleted ? .green : .primary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    // Share
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    // Delete
                    if let task = viewModel.task {
                        modelContext.delete(task)
                        try? modelContext.save()
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
    }
    
    private var statusSection: some View {
        SectionView(title: "Status", icon: "checkmark.circle") {
            Picker("Status", selection: $viewModel.status) {
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    Text(status.name).tag(status)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    private var unselectedTags: [Tag] {
        viewModel.allTags.filter { t in
            !viewModel.selectedTags.contains(where: { $0.id == t.id })
        }
    }

    private func tagPill(_ tag: Tag) -> some View {
        HStack(spacing: 4) {
            Text(tag.name).font(.caption)
            Button(action: {
                viewModel.selectedTags.removeAll { $0.id == tag.id }
                viewModel.save()
            }) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: tag.color).opacity(0.2))
        .foregroundColor(Color(hex: tag.color))
        .cornerRadius(12)
    }

    private var addTagMenu: some View {
        Menu {
            if unselectedTags.isEmpty {
                Text("No tags available")
            } else {
                ForEach(unselectedTags, id: \.id) { tag in
                    Button(tag.name) {
                        viewModel.selectedTags.append(tag)
                        viewModel.save()
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                Text("Add label")
            }
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
    }

    private var labelsSection: some View {
        SectionView(title: "Labels", icon: "tag") {
            FlowLayout {
                ForEach(viewModel.selectedTags) { tag in
                    tagPill(tag)
                }
                addTagMenu
            }
        }
    }
    
    private var assigneeSection: some View {
        SectionView(title: "Assignee", icon: "person") {
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                
                Text("Nathan BUISSON")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    // Change assignee
                }) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var datesSection: some View {
        SectionView(title: "Dates", icon: "calendar") {
            VStack(spacing: 12) {
                HStack {
                    Text("Start date")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let startDate = viewModel.startDate {
                        Text(formatDate(startDate))
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            viewModel.startDate = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button("Set start date") {
                            viewModel.startDate = Date()
                        }
                    }
                }
                
                HStack {
                    Text("Due date")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let dueDate = viewModel.dueDate {
                        Text(formatDate(dueDate))
                            .foregroundColor(viewModel.task?.isOverdue ?? false ? .red : .primary)
                        
                        Button(action: {
                            viewModel.dueDate = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button("Set due date") {
                            viewModel.dueDate = Date()
                        }
                    }
                }
            }
        }
    }
    
    private var repeatSection: some View {
        SectionView(title: "Repeat", icon: "arrow.clockwise") {
            HStack {
                Text("Does not repeat")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Edit") {
                    // Edit repeat
                }
            }
        }
    }
    
    private var bucketSection: some View {
        SectionView(title: "Bucket", icon: "folder") {
            HStack {
                if let project = viewModel.selectedProject {
                    Circle()
                        .fill(Color(hex: project.color ?? "blue"))
                        .frame(width: 8, height: 8)
                    Text(project.name)
                } else {
                    Text("No bucket")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button("None") {
                        viewModel.selectedProject = nil
                    }
                    
                    Divider()
                    
                    ForEach(viewModel.allProjects) { project in
                        Button(project.name) {
                            viewModel.selectedProject = project
                        }
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.secondary)
                    
                    Text("Checklist")
                        .font(.headline)
                }
                
                Spacer()
                
                Text("\(viewModel.task?.completedSubtaskCount ?? 0)/\(viewModel.task?.totalSubtaskCount ?? 0)")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12)
                
                Button(action: { showingSubtaskInput = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            if showingSubtaskInput {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 20, height: 20)
                    
                    TextField("Add an item", text: $newSubtaskTitle)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            addSubtask()
                        }
                    
                    Button("Add") {
                        addSubtask()
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    
                    Button("Cancel") {
                        showingSubtaskInput = false
                        newSubtaskTitle = ""
                    }
                }
                .padding(16)
                .background(Color.secondary.opacity(0.05))
            }
            
            if viewModel.subtasks.isEmpty && !showingSubtaskInput {
                Text("Add an item")
                    .foregroundColor(.secondary)
                    .padding(16)
            } else {
                ForEach(viewModel.subtasks.sorted { $0.orderIndex < $1.orderIndex }, id: \.id) { subtask in
                    InspectorSubtaskRowView(
                        subtask: subtask,
                        onToggle: {
                            viewModel.toggleSubtaskComplete(subtask)
                        },
                        onDelete: {
                            viewModel.deleteSubtask(subtask)
                        }
                    )
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .foregroundColor(.secondary)
                    
                    Text("Notes")
                        .font(.headline)
                }
                
                Spacer()
            }
            .padding(16)
            
            TextEditor(text: $viewModel.notes)
                .frame(minHeight: 150)
                .font(.body)
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
    }
    
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "paperclip")
                        .foregroundColor(.secondary)
                    
                    Text("Attachments")
                        .font(.headline)
                }
                
                Spacer()
                
                Button(action: {
                    // Add attachment
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            Text("Add files, links, or images")
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
        }
    }
    
    private func addSubtask() {
        guard !newSubtaskTitle.isEmpty else { return }
        viewModel.addSubtask(title: newSubtaskTitle)
        newSubtaskTitle = ""
        showingSubtaskInput = false
    }
    
    private func addNewLabel() {
        guard !newLabelName.isEmpty else { return }
        let tag = Tag(name: newLabelName)
        modelContext.insert(tag)
        viewModel.selectedTags.append(tag)
        viewModel.allTags.append(tag)
        newLabelName = ""
        showingAddLabel = false
        try? modelContext.save()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.secondary)
                    
                    Text(title)
                        .font(.headline)
                }
                
                Spacer()
            }
            .padding(16)
            
            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

struct InspectorSubtaskRowView: View {
    let subtask: Subtask
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var isEditingTitle: Bool = false
    @State private var titleText: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(subtask.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            if isEditingTitle {
                TextField("Item", text: $titleText)
                    .textFieldStyle(.plain)
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
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
                    .opacity(0)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.secondary.opacity(0.05))
    }
    
    private func saveTitle() {
        guard isEditingTitle else { return }
        isEditingTitle = false
        
        if !titleText.isEmpty && titleText != subtask.title {
            subtask.title = titleText
        }
    }
}
