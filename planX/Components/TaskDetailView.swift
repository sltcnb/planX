import SwiftUI

struct TaskDetailView: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var newSubtaskTitle: String = ""
    @State private var showingSubtaskInput: Bool = false
    @FocusState private var titleFocused: Bool
    @FocusState private var subtaskFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                titleSection
                
                divider
                
                notesSection
                
                divider
                
                subtasksSection
                
                divider
                
                metadataSection
            }
            .padding(24)
        }
        .onChange(of: viewModel.title) { _, _ in viewModel.save() }
        .onChange(of: viewModel.notes) { _, _ in viewModel.save() }
        .onChange(of: viewModel.dueDate) { _, _ in viewModel.save() }
        .onChange(of: viewModel.priority) { _, _ in viewModel.save() }
        .onChange(of: viewModel.status) { _, _ in viewModel.save() }
        .onChange(of: viewModel.selectedProject) { _, _ in viewModel.save() }
    }
    
    private var divider: some View {
        Divider()
            .padding(.vertical, 8)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Task Title", text: $viewModel.title)
                .font(.system(size: 24, weight: .bold))
                .focused($titleFocused)
                .onAppear { if viewModel.title.isEmpty { titleFocused = true } }
            
            HStack {
                Picker("Status", selection: $viewModel.status) {
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        Text(status.name).tag(status)
                    }
                }
                .pickerStyle(.menu)
                
                Spacer()
                
                Button(action: {
                    viewModel.status = viewModel.status == .done ? .notStarted : .done
                    viewModel.save()
                }) {
                    HStack {
                        Image(systemName: viewModel.status == .done ? "checkmark.circle.fill" : "circle")
                        Text(viewModel.status == .done ? "Completed" : "Mark Complete")
                    }
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $viewModel.notes)
                .frame(minHeight: 150)
                .font(.body)
                .padding(8)
                .background(Color.textBackground)
                .cornerRadius(8)
        }
    }
    
    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Subtasks")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { showingSubtaskInput = true }) {
                    Image(systemName: "plus")
                }
                .help("Add Subtask")
            }
            
            if showingSubtaskInput {
                HStack {
                    TextField("New subtask", text: $newSubtaskTitle)
                        .textFieldStyle(.roundedBorder)
                        .focused($subtaskFocused)
                        .onAppear { subtaskFocused = true }
                        .onSubmit {
                            if !newSubtaskTitle.isEmpty {
                                viewModel.addSubtask(title: newSubtaskTitle)
                                newSubtaskTitle = ""
                            }
                        }
                    
                    Button("Add") {
                        if !newSubtaskTitle.isEmpty {
                            viewModel.addSubtask(title: newSubtaskTitle)
                            newSubtaskTitle = ""
                        }
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    
                    Button("Cancel") {
                        showingSubtaskInput = false
                        newSubtaskTitle = ""
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                }
            }
            
            if viewModel.subtasks.isEmpty {
                Text("No subtasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                SubtaskListView(viewModel: viewModel)
            }
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.secondary)
            
            DatePicker("Due Date", selection: Binding(
                get: { viewModel.dueDate ?? Date() },
                set: { viewModel.dueDate = $0 }
            ), displayedComponents: .date)
            
            HStack {
                Text("Priority")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Priority", selection: $viewModel.priority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        HStack {
                            Circle()
                                .fill(priorityColor(priority))
                                .frame(width: 8, height: 8)
                            Text(priority.name)
                        }
                        .tag(priority)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }
            
            HStack {
                Text("Project")
                    .foregroundColor(.secondary)
                
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
                    
                    Divider()
                    
                    Button("New Project...") {
                        // TODO: Create new project
                    }
                } label: {
                    HStack {
                        if let project = viewModel.selectedProject {
                            Circle()
                                .fill(project.color ?? "blue" == "blue" ? .blue : .green)
                                .frame(width: 8, height: 8)
                            Text(project.name)
                        } else {
                            Text("No Project")
                        }
                    }
                }
            }
            
            HStack {
                Text("Tags")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                FlowLayout {
                    ForEach(viewModel.selectedTags) { tag in
                        TagBadgeView(tag: tag, onRemove: {
                            viewModel.selectedTags.removeAll { $0.id == tag.id }
                            viewModel.save()
                        })
                    }
                    
                    Menu {
                        ForEach(viewModel.allTags.filter { !viewModel.selectedTags.contains($0) }) { tag in
                            Button(tag.name) {
                                viewModel.selectedTags.append(tag)
                                viewModel.save()
                            }
                        }
                        
                        Divider()
                        
                        Button("New Tag...") {
                            // TODO: Create new tag
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
        
        return CGSize(width: width, height: currentY + rowHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .init(size))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

struct TagBadgeView: View {
    let tag: Tag
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag.name)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

extension Color {
    static var textBackground: Color {
        Color(NSColor.textBackgroundColor)
    }

    init(hex: String) {
        let lower = hex.lowercased()
        switch lower {
        case "red":     self = .red
        case "green":   self = .green
        case "blue":    self = .blue
        case "orange":  self = .orange
        case "yellow":  self = .yellow
        case "purple":  self = .purple
        case "pink":    self = Color(red: 1, green: 0.41, blue: 0.71)
        case "gray", "grey": self = .gray
        case "cyan":    self = .cyan
        case "mint":    self = .mint
        case "indigo":  self = .indigo
        case "teal":    self = .teal
        default:
            // Try parsing as a hex color (#RRGGBB or RRGGBB)
            var hexStr = lower.hasPrefix("#") ? String(lower.dropFirst()) : lower
            if hexStr.count == 3 {
                hexStr = hexStr.flatMap { [String($0), String($0)] }.joined()
            }
            guard hexStr.count == 6, let value = UInt64(hexStr, radix: 16) else {
                self = .blue
                return
            }
            let r = Double((value >> 16) & 0xFF) / 255
            let g = Double((value >> 8) & 0xFF) / 255
            let b = Double(value & 0xFF) / 255
            self = Color(red: r, green: g, blue: b)
        }
    }
}
