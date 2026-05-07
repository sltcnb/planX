import SwiftUI

struct QuickAddView: View {
    @ObservedObject var viewModel: QuickAddViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                
                Text("Quick Add Task")
                    .font(.headline)
            }
            
            TextField("Enter task (e.g., 'Finish tax documents tomorrow high #admin')", text: $viewModel.inputText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 16))
                .focused($inputFocused)
                .onChange(of: viewModel.inputText) { _, _ in
                    viewModel.parseInput()
                }
                .onSubmit {
                    viewModel.addTask()
                }
                .onAppear { inputFocused = true }
            
            if let info = viewModel.parsedInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Label(info.title, systemImage: "text.alignleft")
                        
                        if let dueDate = info.dueDate {
                            Label(formatDate(dueDate), systemImage: "calendar")
                        }
                        
                        Label(info.priority.name, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(priorityColor(info.priority))
                        
                        ForEach(info.tags, id: \.self) { tag in
                            Label("#\(tag)", systemImage: "tag.fill")
                        }
                        
                        if let project = info.project {
                            Label("@\(project)", systemImage: "folder.fill")
                        }
                    }
                    .font(.caption)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Add Task") {
                    viewModel.addTask()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(viewModel.parsedInfo == nil)
            }
        }
        .padding(24)
        .frame(width: 500)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
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
