import SwiftUI
import SwiftData

struct TaskDetailModalView: View {
    let task: TaskItem
    let onDismiss: () -> Void
    var onWillDelete: (() -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var notes: String
    @State private var status: TaskStatus
    @State private var priority: Priority
    @State private var dueDate: Date?
    @State private var startDate: Date?
    @State private var selectedProject: Project?
    @State private var selectedTags: [Tag]
    @State private var subtasks: [Subtask]
    @State private var newSubtaskTitle = ""
    @State private var showingSubtaskInput = false
    @State private var allProjects: [Project] = []
    @State private var allTags: [Tag] = []
    @State private var newTagName = ""
    @State private var showingNewTagInput = false
    @State private var isTracking = false
    @State private var allTasks: [TaskItem] = []
    @State private var showingDependencyPicker = false
    @State private var pendingDepType = "blocks"
    @State private var isDeleted = false
    @FocusState private var newTagFocused: Bool
    @FocusState private var newSubtaskFocused: Bool

    init(task: TaskItem, onDismiss: @escaping () -> Void, onWillDelete: (() -> Void)? = nil) {
        self.task = task
        self.onDismiss = onDismiss
        self.onWillDelete = onWillDelete
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes)
        _status = State(initialValue: task.statusValue)
        _priority = State(initialValue: task.priorityValue)
        _dueDate = State(initialValue: task.dueDate)
        _startDate = State(initialValue: task.startDate)
        _selectedProject = State(initialValue: task.project)
        _selectedTags = State(initialValue: task.tags)
        _subtasks = State(initialValue: task.subtasks.sorted { $0.orderIndex < $1.orderIndex })
    }

    var body: some View {
        VStack(spacing: 0) {
            modalHeader
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    metaSection
                    Divider()
                    datesSection
                    Divider()
                    projectTagsSection
                    Divider()
                    subtasksSection
                    Divider()
                    dependenciesSection
                    Divider()
                    timerSection
                    Divider()
                    notesSection
                }
            }
        }
        .frame(minWidth: 640, minHeight: 520)
        .onAppear { loadData() }
        .onDisappear {
            if !isDeleted {
                save()
                onDismiss()
            }
        }
    }

    private var modalHeader: some View {
        HStack(spacing: 12) {
            Button(action: {
                task.isCompleted.toggle()
                status = task.isCompleted ? .done : .notStarted
                save()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .secondary)
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)

            TextField("Task title", text: $title)
                .font(.title3.weight(.semibold))
                .textFieldStyle(.plain)

            Spacer()

            Button(action: {
                isDeleted = true
                onWillDelete?()
                dismiss()
                onDismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    let tid = task.id
                    if let allDeps = try? modelContext.fetch(FetchDescriptor<TaskDependency>()) {
                        for dep in allDeps where dep.predecessor?.id == tid || dep.successor?.id == tid {
                            modelContext.delete(dep)
                        }
                    }
                    modelContext.delete(task)
                    try? modelContext.save()
                }
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Button(action: dismiss.callAsFunction) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var metaSection: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Status").font(.caption).foregroundColor(.secondary)
                Picker("Status", selection: $status) {
                    ForEach(TaskStatus.allCases, id: \.self) { s in
                        Text(s.name).tag(s)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Priority").font(.caption).foregroundColor(.secondary)
                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases, id: \.self) { p in
                        Text(p.name).tag(p)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var datesSection: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Start Date").font(.caption).foregroundColor(.secondary)
                if let date = startDate {
                    HStack {
                        DatePicker("", selection: Binding(get: { date }, set: { startDate = $0 }), displayedComponents: .date)
                            .labelsHidden()
                        Button(action: { startDate = nil }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button("Set date") { startDate = Date() }
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Due Date").font(.caption).foregroundColor(.secondary)
                if let date = dueDate {
                    HStack {
                        DatePicker("", selection: Binding(get: { date }, set: { dueDate = $0 }), displayedComponents: .date)
                            .labelsHidden()
                        Button(action: { dueDate = nil }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button("Set date") { dueDate = Date() }
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var projectTagsSection: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Project").font(.caption).foregroundColor(.secondary)
                Menu {
                    Button("None") { selectedProject = nil }
                    Divider()
                    ForEach(allProjects, id: \.id) { project in
                        Button(project.name) { selectedProject = project }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if let p = selectedProject {
                            Circle().fill(Color(hex: p.color ?? "blue")).frame(width: 8, height: 8)
                            Text(p.name)
                        } else {
                            Text("No project").foregroundColor(.secondary)
                        }
                        Image(systemName: "chevron.down").font(.caption2).foregroundColor(.secondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Tags").font(.caption).foregroundColor(.secondary)
                HStack(spacing: 6) {
                    ForEach(selectedTags, id: \.id) { tag in
                        HStack(spacing: 3) {
                            Text(tag.name).font(.caption)
                            Button(action: { selectedTags.removeAll { $0.id == tag.id } }) {
                                Image(systemName: "xmark").font(.system(size: 8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color(hex: tag.color).opacity(0.2))
                        .foregroundColor(Color(hex: tag.color))
                        .cornerRadius(10)
                    }

                    if showingNewTagInput {
                        HStack(spacing: 4) {
                            TextField("Tag name", text: $newTagName)
                                .textFieldStyle(.plain)
                                .frame(width: 90)
                                .focused($newTagFocused)
                                .onAppear { newTagFocused = true }
                                .onSubmit { createAndAddTag() }
                            Button("Add") { createAndAddTag() }.font(.caption)
                            Button(action: { showingNewTagInput = false; newTagName = "" }) {
                                Image(systemName: "xmark").font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.caption)
                    } else {
                        Menu {
                            let unselected = allTags.filter { t in !selectedTags.contains(where: { $0.id == t.id }) }
                            ForEach(unselected, id: \.id) { tag in
                                Button(tag.name) { selectedTags.append(tag) }
                            }
                            if !unselected.isEmpty { Divider() }
                            Button("New tag…") { showingNewTagInput = true }
                        } label: {
                            Image(systemName: "plus.circle").foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle").foregroundColor(.secondary)
                Text("Subtasks").font(.headline)
                Spacer()
                Text("\(subtasks.filter { $0.isCompleted }.count)/\(subtasks.count)")
                    .font(.caption).foregroundColor(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(12)
                Button(action: { showingSubtaskInput = true }) {
                    Image(systemName: "plus").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            ForEach(subtasks, id: \.id) { subtask in
                ModalSubtaskRow(subtask: subtask, onToggle: {
                    subtask.isCompleted.toggle()
                    subtask.updatedAt = Date()
                    try? modelContext.save()
                    subtasks = task.subtasks.sorted { $0.orderIndex < $1.orderIndex }
                }, onDelete: {
                    modelContext.delete(subtask)
                    try? modelContext.save()
                    subtasks = task.subtasks.sorted { $0.orderIndex < $1.orderIndex }
                })
            }

            if showingSubtaskInput {
                HStack(spacing: 8) {
                    Image(systemName: "circle").foregroundColor(.secondary).font(.system(size: 14))
                    TextField("Add subtask", text: $newSubtaskTitle)
                        .textFieldStyle(.plain)
                        .focused($newSubtaskFocused)
                        .onAppear { newSubtaskFocused = true }
                        .onSubmit { addSubtask() }
                    Button("Add") { addSubtask() }
                    Button("Cancel") { showingSubtaskInput = false; newSubtaskTitle = "" }
                        .foregroundColor(.secondary)
                }
                .font(.body)
            }

            if subtasks.isEmpty && !showingSubtaskInput {
                Button(action: { showingSubtaskInput = true }) {
                    Label("Add a subtask", systemImage: "plus")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text").foregroundColor(.secondary)
                Text("Notes").font(.headline)
                Spacer()
                Toggle("Show on kanban", isOn: Binding(
                    get: { task.showNotesOnKanban },
                    set: { task.showNotesOnKanban = $0 }
                ))
                .toggleStyle(.checkbox)
                .font(.caption)
            }

            TextEditor(text: $notes)
                .font(.body)
                .frame(minHeight: 160)
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                .scrollContentBackground(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func loadData() {
        let projDesc = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.name)])
        allProjects = (try? modelContext.fetch(projDesc)) ?? []
        let tagDesc = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        allTags = (try? modelContext.fetch(tagDesc)) ?? []
        let taskDesc = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.title)])
        allTasks = ((try? modelContext.fetch(taskDesc)) ?? []).filter { $0.id != task.id }
        isTracking = TimeTrackingService.shared.isTrackingTime(for: task)
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "timer").foregroundColor(.secondary)
                Text("Time Tracking").font(.headline)
                Spacer()
                Text(task.formattedTotalTime)
                    .font(.caption).foregroundColor(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(10)
            }

            HStack(spacing: 12) {
                if isTracking {
                    Button(action: {
                        TimeTrackingService.shared.stopTracking(for: task, context: modelContext)
                        isTracking = false
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button(action: {
                        _ = TimeTrackingService.shared.startTracking(for: task, description: nil, context: modelContext)
                        isTracking = true
                    }) {
                        Label("Start Timer", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }

                if task.timeEntries.isEmpty == false {
                    Text("\(task.timeEntries.count) entr\(task.timeEntries.count == 1 ? "y" : "ies")")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var dependenciesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "link").foregroundColor(.secondary)
                Text("Links").font(.headline)
                Spacer()
                Menu {
                    Button("Blocked by…") { pendingDepType = "blocked_by"; showingDependencyPicker = true }
                    Button("Blocks…") { pendingDepType = "blocks"; showingDependencyPicker = true }
                    Button("Related to…") { pendingDepType = "related"; showingDependencyPicker = true }
                } label: {
                    Image(systemName: "plus").foregroundColor(.secondary)
                }
            }

            let blocked = task.blockedByTasks
            let blocking = task.blockingTasks
            let related = task.dependencies.filter { $0.relationshipType == "related" }
                .compactMap { dep -> TaskItem? in
                    dep.predecessor?.id == task.id ? dep.successor : dep.predecessor
                }

            if blocked.isEmpty && blocking.isEmpty && related.isEmpty {
                Text("No links")
                    .font(.callout).foregroundColor(.secondary)
            }

            if !blocked.isEmpty {
                depGroup(label: "Blocked by", icon: "lock.fill", color: .orange, tasks: blocked, type: "blocked_by")
            }
            if !blocking.isEmpty {
                depGroup(label: "Blocks", icon: "bolt.fill", color: .red, tasks: blocking, type: "blocks")
            }
            if !related.isEmpty {
                depGroup(label: "Related", icon: "arrow.left.arrow.right", color: .blue, tasks: related, type: "related")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .sheet(isPresented: $showingDependencyPicker) {
            DependencyPickerView(task: task) { other, type in
                if pendingDepType == "blocked_by" {
                    DependencyService.shared.addDependency(from: other, to: task, type: "blocks", context: modelContext)
                } else if pendingDepType == "blocks" {
                    DependencyService.shared.addDependency(from: task, to: other, type: "blocks", context: modelContext)
                } else {
                    DependencyService.shared.addDependency(from: task, to: other, type: "related", context: modelContext)
                }
                loadData()
            }
        }
    }

    @ViewBuilder
    private func depGroup(label: String, icon: String, color: Color, tasks: [TaskItem], type: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
            ForEach(tasks, id: \.id) { t in
                HStack(spacing: 6) {
                    Image(systemName: t.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 11))
                        .foregroundColor(t.isCompleted ? .green : .secondary)
                    Text(t.title)
                        .font(.callout)
                        .strikethrough(t.isCompleted)
                    Spacer()
                    Button(action: {
                        if let dep = task.dependencies.first(where: {
                            ($0.predecessor?.id == task.id && $0.successor?.id == t.id) ||
                            ($0.successor?.id == task.id && $0.predecessor?.id == t.id)
                        }) {
                            DependencyService.shared.removeDependency(dep, context: modelContext)
                            loadData()
                        }
                    }) {
                        Image(systemName: "xmark").font(.caption2).foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func save() {
        task.title = title
        task.notes = notes
        task.statusValue = status
        task.priorityValue = priority
        task.dueDate = dueDate
        task.startDate = startDate
        task.project = selectedProject
        task.tags = selectedTags
        task.updatedAt = Date()
        if task.isCompleted && task.completedAt == nil { task.completedAt = Date() }
        try? modelContext.save()
    }

    private func addSubtask() {
        guard !newSubtaskTitle.isEmpty else { return }
        let order = (subtasks.map { $0.orderIndex }.max() ?? -1) + 1
        let subtask = Subtask(title: newSubtaskTitle, isCompleted: false, orderIndex: order)
        subtask.parentTask = task
        task.subtasks.append(subtask)
        modelContext.insert(subtask)
        try? modelContext.save()
        subtasks = task.subtasks.sorted { $0.orderIndex < $1.orderIndex }
        newSubtaskTitle = ""
        showingSubtaskInput = false
    }

    private func createAndAddTag() {
        guard !newTagName.isEmpty else { return }
        let colors = ["blue", "green", "orange", "red", "purple", "pink", "teal", "indigo"]
        let tag = Tag(name: newTagName, color: colors.randomElement() ?? "blue")
        modelContext.insert(tag)
        selectedTags.append(tag)
        allTags.append(tag)
        try? modelContext.save()
        newTagName = ""
        showingNewTagInput = false
    }
}

struct ModalSubtaskRow: View {
    let subtask: Subtask
    let onToggle: () -> Void
    let onDelete: () -> Void
    @State private var isEditing = false
    @State private var editTitle = ""
    @FocusState private var editFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(subtask.isCompleted ? .green : .secondary)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("", text: $editTitle)
                    .textFieldStyle(.plain)
                    .focused($editFocused)
                    .onAppear { editFocused = true }
                    .onSubmit {
                        if !editTitle.isEmpty { subtask.title = editTitle }
                        isEditing = false
                    }
                    .onExitCommand { isEditing = false }
            } else {
                Text(subtask.title)
                    .strikethrough(subtask.isCompleted)
                    .foregroundColor(subtask.isCompleted ? .secondary : .primary)
                    .contentShape(Rectangle())
                    .onTapGesture { editTitle = subtask.title; isEditing = true }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash").foregroundColor(.secondary).font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 3)
    }
}
