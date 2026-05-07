import SwiftUI

struct TodayView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var selectedTask: TaskItem?
    @Environment(\.modelContext) private var modelContext
    
    private var overdueTasks: [TaskItem] {
        viewModel.tasks.filter { $0.isOverdue }
    }
    
    private var dueTodayTasks: [TaskItem] {
        viewModel.tasks.filter { $0.isDueToday && !$0.isCompleted }
    }
    
    private var importantTasks: [TaskItem] {
        viewModel.tasks.filter { $0.priorityValue == .high && !$0.isCompleted }
    }
    
    private var inProgressTasks: [TaskItem] {
        viewModel.tasks.filter { $0.statusValue == .inProgress }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                dateHeader
                
                if !overdueTasks.isEmpty {
                    taskSection(title: "Overdue", icon: "exclamationmark.circle.fill", color: .red, tasks: overdueTasks)
                }
                
                if !dueTodayTasks.isEmpty {
                    taskSection(title: "Due Today", icon: "sun.max.fill", color: .orange, tasks: dueTodayTasks)
                }
                
                if !importantTasks.isEmpty {
                    taskSection(title: "Important", icon: "star.fill", color: .yellow, tasks: importantTasks)
                }
                
                if !inProgressTasks.isEmpty {
                    taskSection(title: "In Progress", icon: "arrow.triangle.2.circlepath", color: .blue, tasks: inProgressTasks)
                }
                
                if overdueTasks.isEmpty && dueTodayTasks.isEmpty && importantTasks.isEmpty && inProgressTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.green)
                        
                        Text("All clear for today!")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("No tasks due today. Time to relax or get ahead on upcoming tasks.")
                            .font(.body)
                            .foregroundColor(.secondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                }
            }
            .padding(24)
        }
    }
    
    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dayOfWeek())
                .font(.title)
                .fontWeight(.bold)
            
            Text(formattedDate())
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
    
    private func taskSection(title: String, icon: String, color: Color, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            VStack(spacing: 4) {
                ForEach(tasks.prefix(5), id: \.id) { task in
                    TaskRowView(
                        task: task,
                        isSelected: selectedTask?.id == task.id,
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
                
                if tasks.count > 5 {
                    Text("+\(tasks.count - 5) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
            }
        }
    }
    
    private func dayOfWeek() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }
}
