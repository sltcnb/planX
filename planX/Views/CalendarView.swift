import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var selectedTask: TaskItem?
    @Environment(\.modelContext) private var modelContext

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDay: Date? = Calendar.current.startOfDay(for: Date())

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    @State private var cellHeight: CGFloat = 110

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                monthHeader
                Divider()
                weekdayRow
                Divider()
                calendarGrid
            }

            if let day = selectedDay {
                Divider()
                dayPanel(for: day)
                    .frame(width: 280)
            }
        }
    }

    // MARK: - Header

    private var monthHeader: some View {
        HStack(spacing: 12) {
            Button(action: shiftMonth(-1)) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Text(monthYearString(displayedMonth))
                .font(.title3)
                .fontWeight(.semibold)
                .frame(minWidth: 160)

            Button(action: shiftMonth(1)) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Today") {
                displayedMonth = cal.startOfMonth(for: Date())
                selectedDay = cal.startOfDay(for: Date())
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
            .font(.subheadline)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var weekdayRow: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(weekdays, id: \.self) { label in
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 8)
    }

    private var calendarGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, day in
                    if let day {
                        DayCell(
                            date: day,
                            tasks: tasksFor(day),
                            isToday: cal.isDateInToday(day),
                            isSelected: selectedDay.map { cal.isDate($0, inSameDayAs: day) } ?? false,
                            onSelect: { selectedDay = day },
                            onTaskTap: { selectedTask = $0 }
                        )
                        .frame(height: cellHeight)
                    } else {
                        Color.clear.frame(height: cellHeight)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .onAppear { updateCellHeight() }
        .onChange(of: viewModel.tasks.count) { updateCellHeight() }
    }

    private func updateCellHeight() {
        let maxTasksPerDay = daysInMonth().compactMap { $0 }.map { tasksFor($0).count }.max() ?? 0
        let pillHeight: CGFloat = 18
        let headerHeight: CGFloat = 30
        let padding: CGFloat = 14
        cellHeight = max(90, headerHeight + CGFloat(min(maxTasksPerDay, 3)) * (pillHeight + 2) + padding)
    }

    // MARK: - Day panel

    private func dayPanel(for day: Date) -> some View {
        let tasks = tasksFor(day)
        return VStack(alignment: .leading, spacing: 0) {
            Text(dayHeaderString(day))
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            Divider()
            if tasks.isEmpty {
                Spacer()
                Text("No tasks")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(tasks, id: \.id) { task in
                            CalendarPanelTaskRow(
                                task: task,
                                isSelected: selectedTask?.modelContext != nil && selectedTask?.id == task.id,
                                onTap: { selectedTask = task },
                                onToggleComplete: { toggleComplete(task) }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Helpers

    private func tasksFor(_ date: Date) -> [TaskItem] {
        viewModel.getFilteredTasks().filter { task in
            guard let due = task.dueDate else { return false }
            return cal.isDate(due, inSameDayAs: date)
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = cal.dateComponents([.weekday], from: interval.start).weekday
        else { return [] }

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        var cursor = interval.start
        while cursor < interval.end {
            days.append(cursor)
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func shiftMonth(_ delta: Int) -> () -> Void {
        { displayedMonth = cal.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth }
    }

    private func toggleComplete(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.updatedAt = Date()
        task.completedAt = task.isCompleted ? Date() : nil
        try? modelContext.save()
        viewModel.refresh()
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func dayHeaderString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: date)
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let tasks: [TaskItem]
    let isToday: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    let onTaskTap: (TaskItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 11, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? .white : .primary)
                    .frame(width: 20, height: 20)
                    .background(isToday ? Color.accentColor : Color.clear)
                    .clipShape(Circle())
                Spacer()
                if tasks.count > 2 {
                    Text("+\(tasks.count - 2)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }

            ForEach(tasks.prefix(2), id: \.id) { task in
                Button(action: { onTaskTap(task) }) {
                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(priorityColor(task.priorityValue))
                            .frame(width: 3, height: 10)
                        Text(task.title.isEmpty ? "Untitled" : task.title)
                            .font(.system(size: 9.5))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(priorityColor(task.priorityValue).opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(NSColor.controlBackgroundColor).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isSelected ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
                )
        )
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
}

// MARK: - Calendar Panel Task Row

struct CalendarPanelTaskRow: View {
    let task: TaskItem
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Button(action: onToggleComplete) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15))
                        .foregroundColor(task.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title.isEmpty ? "Untitled" : task.title)
                        .font(.system(size: 12))
                        .lineLimit(2)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 6) {
                        if task.priorityValue != .low {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(task.priorityValue == .high ? Color.red : Color.orange)
                                .frame(width: 6, height: 6)
                        }
                        if let project = task.project {
                            Text(project.name)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        if task.hasSubtasks {
                            Text("\(task.completedSubtaskCount)/\(task.totalSubtaskCount)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(task.isCompleted ? "Mark Incomplete" : "Mark Complete") { onToggleComplete() }
        }
    }
}

// MARK: - Calendar extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
