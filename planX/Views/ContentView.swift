import SwiftUI
import SwiftData

enum ViewMode { case board, calendar, graph }

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var quickAddViewModel = QuickAddViewModel()
    @State private var selectedTask: TaskItem?
    @State private var taskDetailViewModel = TaskDetailViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var viewMode: ViewMode = .board

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(viewModel: appViewModel)
                .frame(width: 200)

            Divider()

            switch viewMode {
            case .board:
                planXBoardView(viewModel: appViewModel, selectedTask: $selectedTask)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .calendar:
                CalendarView(viewModel: appViewModel, selectedTask: $selectedTask)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .graph:
                TaskGraphView(viewModel: appViewModel, selectedTask: $selectedTask)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            appViewModel.setModelContext(modelContext)
            quickAddViewModel.setModelContext(modelContext)
            appViewModel.refresh()
        }
        .sheet(isPresented: $appViewModel.showQuickAdd) {
            QuickAddView(viewModel: quickAddViewModel)
                .onAppear {
                    quickAddViewModel.onTaskAdded = {
                        appViewModel.refresh()
                    }
                }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailModalView(task: task, onDismiss: {
                appViewModel.refresh()
            }, onWillDelete: {
                let taskID = task.id
                selectedTask = nil
                appViewModel.tasks.removeAll { $0.id == taskID }
            })
        }
        .searchable(text: $appViewModel.searchText, prompt: "Search tasks")
        .onChange(of: appViewModel.searchText) { appViewModel.refresh() }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Picker("Sort", selection: $appViewModel.sortOrder) {
                    Text("Due Date").tag(AppViewModel.SortOrder.dueDate)
                    Text("Priority").tag(AppViewModel.SortOrder.priority)
                    Text("Title").tag(AppViewModel.SortOrder.title)
                    Text("Created").tag(AppViewModel.SortOrder.createdAt)
                }
                .pickerStyle(.menu)

                if appViewModel.isSelectMode {
                    Button("Select All") {
                        appViewModel.selectedTaskIDs = Set(appViewModel.getFilteredTasks().map { $0.id })
                    }
                    .keyboardShortcut("a", modifiers: .command)

                    if !appViewModel.selectedTaskIDs.isEmpty {
                        Button(action: deleteSelectedTasks) {
                            Label("Delete (\(appViewModel.selectedTaskIDs.count))", systemImage: "trash")
                        }
                        .foregroundColor(.red)
                    }
                    Button("Done") {
                        appViewModel.isSelectMode = false
                        appViewModel.selectedTaskIDs = []
                    }
                } else {
                    Picker("View", selection: $viewMode) {
                        Image(systemName: "rectangle.split.3x1").tag(ViewMode.board)
                        Image(systemName: "calendar").tag(ViewMode.calendar)
                        Image(systemName: "point.3.connected.trianglepath.dotted").tag(ViewMode.graph)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                    Button(action: { appViewModel.isSelectMode = true }) {
                        Label("Select", systemImage: "checkmark.circle")
                    }
                    Button(action: { appViewModel.showQuickAdd = true }) {
                        Label("Quick Add", systemImage: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    Button(action: { createAndOpenNewTask() }) {
                        Label("Full Form", systemImage: "square.and.pencil")
                    }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                }
            }
        }
    }

    private func createAndOpenNewTask(status: TaskStatus = .notStarted) {
        let task = TaskItem(title: "")
        task.statusValue = status
        modelContext.insert(task)
        try? modelContext.save()
        appViewModel.refresh()
        selectedTask = task
    }

    private func deleteSelectedTasks() {
        let ids = appViewModel.selectedTaskIDs
        if let sel = selectedTask, ids.contains(sel.id) { selectedTask = nil }
        let toDelete = appViewModel.tasks.filter { ids.contains($0.id) }
        appViewModel.tasks.removeAll { ids.contains($0.id) }
        appViewModel.selectedTaskIDs = []
        appViewModel.isSelectMode = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let tpids = Set(toDelete.map { $0.persistentModelID })
            if let allDeps = try? modelContext.fetch(FetchDescriptor<TaskDependency>()) {
                for dep in allDeps {
                    let pp = dep.predecessor?.persistentModelID
                    let sp = dep.successor?.persistentModelID
                    if pp.map({ tpids.contains($0) }) ?? true || sp.map({ tpids.contains($0) }) ?? true {
                        modelContext.delete(dep)
                    }
                }
            }
            for task in toDelete { modelContext.delete(task) }
            try? modelContext.save()
            appViewModel.refresh()
        }
    }
}
