import SwiftUI
import SwiftData

struct SidebarView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingNewProject = false
    @State private var newProjectName = ""
    @State private var showingNewTag = false
    @State private var newTagName = ""
    @State private var tagsExpanded = true
    @FocusState private var projectNameFocused: Bool
    @FocusState private var tagNameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("planX")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            List {
                Button(action: {
                    viewModel.selectedProject = nil
                    viewModel.selectedTag = nil
                    viewModel.refresh()
                }) {
                    Label("All Tasks", systemImage: "tray.full")
                        .foregroundColor(viewModel.selectedProject == nil && viewModel.selectedTag == nil ? .accentColor : .primary)
                }
                .buttonStyle(.plain)

                Section("Projects") {
                    ForEach(viewModel.projects) { project in
                        Button(action: {
                            viewModel.selectedProject = project
                            viewModel.selectedTag = nil
                            viewModel.refresh()
                        }) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(hex: project.color ?? "blue"))
                                    .frame(width: 8, height: 8)
                                Text(project.name)
                                    .foregroundColor(viewModel.selectedProject?.id == project.id ? .accentColor : .primary)
                                Spacer()
                                Text("\(project.completedCount)/\(project.taskCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                modelContext.delete(project)
                                try? modelContext.save()
                                viewModel.loadProjects()
                            }
                        }
                    }

                    Button(action: { showingNewProject = true }) {
                        Label("New Project", systemImage: "plus")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Section {
                    DisclosureGroup(isExpanded: $tagsExpanded) {
                        ForEach(viewModel.tags) { tag in
                            Button(action: {
                                viewModel.selectedTag = tag
                                viewModel.selectedProject = nil
                                viewModel.refresh()
                            }) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: tag.color))
                                        .frame(width: 8, height: 8)
                                    Text(tag.name)
                                        .foregroundColor(viewModel.selectedTag?.id == tag.id ? .accentColor : .primary)
                                }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    modelContext.delete(tag)
                                    try? modelContext.save()
                                    viewModel.loadTags()
                                }
                            }
                        }
                        Button(action: { showingNewTag = true }) {
                            Label("New Tag", systemImage: "plus")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    } label: {
                        Button(action: { tagsExpanded.toggle() }) {
                            Label("Tags", systemImage: "tag.fill")
                                .foregroundColor(viewModel.selectedTag != nil ? .accentColor : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .onAppear { viewModel.refresh() }
        .sheet(isPresented: $showingNewProject) {
            newProjectSheet
        }
        .sheet(isPresented: $showingNewTag) {
            newTagSheet
        }
    }

    private var newProjectSheet: some View {
        VStack(spacing: 16) {
            Text("New Project").font(.headline)
            TextField("Project name", text: $newProjectName)
                .textFieldStyle(.roundedBorder)
                .focused($projectNameFocused)
                .onAppear { projectNameFocused = true }
                .onSubmit { createProject() }
            HStack {
                Button("Cancel") { showingNewProject = false; newProjectName = "" }
                Spacer()
                Button("Create") { createProject() }
                    .disabled(newProjectName.isEmpty)
                    .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    private var newTagSheet: some View {
        VStack(spacing: 16) {
            Text("New Tag").font(.headline)
            TextField("Tag name", text: $newTagName)
                .textFieldStyle(.roundedBorder)
                .focused($tagNameFocused)
                .onAppear { tagNameFocused = true }
                .onSubmit { createTag() }
            HStack {
                Button("Cancel") { showingNewTag = false; newTagName = "" }
                Spacer()
                Button("Create") { createTag() }
                    .disabled(newTagName.isEmpty)
                    .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    private func createProject() {
        guard !newProjectName.isEmpty else { return }
        let colors = ["blue", "green", "orange", "red", "purple", "teal"]
        let project = Project(name: newProjectName, color: colors.randomElement() ?? "blue")
        modelContext.insert(project)
        try? modelContext.save()
        viewModel.loadProjects()
        showingNewProject = false
        newProjectName = ""
    }

    private func createTag() {
        guard !newTagName.isEmpty else { return }
        let colors = ["blue", "green", "orange", "red", "purple", "pink", "yellow", "teal", "indigo"]
        let tag = Tag(name: newTagName, color: colors.randomElement() ?? "blue")
        modelContext.insert(tag)
        try? modelContext.save()
        viewModel.loadTags()
        showingNewTag = false
        newTagName = ""
    }
}
