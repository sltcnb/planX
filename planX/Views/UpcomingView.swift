import SwiftUI

struct UpcomingView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var selectedTask: TaskItem?
    @Environment(\.modelContext) private var modelContext
    
    private var tomorrowTasks: [TaskItem] {
        viewModel.tasks.filter { $0.isDueTomorrow && !$0.isCompleted }
    }
    
    private var thisWeekTasks: [TaskItem] {
        viewModel.tasks.filter { $0.isDueThisWeek && !$0.isDueToday && !$0.isDueTomorrow && !$0.isCompleted }
    }
    
    private var laterTasks: [TaskItem] {
        viewModel.tasks.filter { $0.dueDate != nil && !$0.isDueThisWeek && !$0.isCompleted }
    }
    
    private var noDateTasks: [TaskItem] {
        viewModel.tasks.filter { $0.dueDate == nil && !$0.isCompleted }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.title)
                    Text("Upcoming")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                if !tomorrowTasks.isEmpty {
                    taskSection(title: "Tomorrow", tasks: tomorrowTasks)
                }
                
                if !thisWeekTasks.isEmpty {
                    taskSection(title: "This Week", tasks: thisWeekTasks)
                }
                
                if !laterTasks.isEmpty {
                    taskSection(title: "Later", tasks: laterTasks)
                }
                
                if !noDateTasks.isEmpty {
                    taskSection(title: "No Due Date", tasks: noDateTasks)
                }
                
                if tomorrowTasks.isEmpty && thisWeekTasks.isEmpty && laterTasks.isEmpty && noDateTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        
                        Text("No upcoming tasks")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                }
            }
            .padding(24)
        }
    }
    
    private func taskSection(title: String, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                ForEach(tasks, id: \.id) { task in
                    TaskRowView(
                        task: task,
                        isSelected: selectedTask?.modelContext != nil && selectedTask?.id == task.id,
                        onTap: { selectedTask = task },
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
                        }
                    )
                }
            }
        }
    }
}
