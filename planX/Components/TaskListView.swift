import SwiftUI
import SwiftData

struct TaskListView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var selectedTask: TaskItem?
    @Environment(\.modelContext) private var modelContext
    
    var filteredTasks: [TaskItem] {
        viewModel.getFilteredTasks()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if filteredTasks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: viewModel.selectedNavigationItem == .completed ? "checkmark.circle" : "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No tasks")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Press ⌘N to add a task")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedTask) {
                    ForEach(filteredTasks, id: \.id) { task in
                        TaskRowView(
                            task: task,
                            isSelected: selectedTask?.modelContext != nil && selectedTask?.id == task.id,
                            onTap: {
                                selectedTask = task
                            },
                            onToggleComplete: {
                                task.isCompleted.toggle()
                                task.updatedAt = Date()
                                if task.isCompleted {
                                    task.completedAt = Date()
                                } else {
                                    task.completedAt = nil
                                }
                                try? modelContext.save()
                                viewModel.refresh()
                            },
                            onDelete: {
                                if selectedTask?.id == task.id { selectedTask = nil }
                                viewModel.tasks.removeAll { $0.id == task.id }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    let tpid = task.persistentModelID
                                    if let allDeps = try? modelContext.fetch(FetchDescriptor<TaskDependency>()) {
                                        for dep in allDeps {
                                            let pp = dep.predecessor?.persistentModelID
                                            let sp = dep.successor?.persistentModelID
                                            if pp == tpid || sp == tpid || pp == nil || sp == nil {
                                                modelContext.delete(dep)
                                            }
                                        }
                                    }
                                    modelContext.delete(task)
                                    try? modelContext.save()
                                    viewModel.refresh()
                                }
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .tag(task)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let task = filteredTasks[index]
                            modelContext.delete(task)
                        }
                        try? modelContext.save()
                        viewModel.refresh()
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { viewModel.showQuickAdd = true }) {
                    Image(systemName: "plus")
                }
                .help("Quick Add Task (⌘N)")
                
                Menu {
                    Picker("Priority", selection: $viewModel.filterPriority) {
                        Text("All").tag(nil as Priority?)
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.name).tag(priority as Priority?)
                        }
                    }
                    
                    Picker("Status", selection: $viewModel.filterStatus) {
                        Text("All").tag(nil as TaskStatus?)
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.name).tag(status as TaskStatus?)
                        }
                    }
                    
                    Divider()
                    
                    Button("Clear Filters") {
                        viewModel.filterPriority = nil
                        viewModel.filterStatus = nil
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search tasks")
    }
}
