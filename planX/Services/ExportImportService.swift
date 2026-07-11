import Foundation
import SwiftData

@MainActor
class ExportImportService {
    static let shared = ExportImportService()
    
    func exportAllTasks(format: ExportFormat, context: ModelContext) -> Data? {
        do {
            let tasks = try context.fetch(FetchDescriptor<TaskItem>())
            switch format {
            case .json: return exportToJSON(tasks)
            case .csv: return exportToCSV(tasks)
            }
        } catch {
            print("Error exporting tasks: \(error)")
            return nil
        }
    }
    
    func importTasks(from data: Data, format: ImportFormat, context: ModelContext) -> [TaskItem] {
        var importedTasks: [TaskItem] = []
        
        switch format {
        case .json:
            importedTasks = importFromJSON(data, context: context)
        case .csv:
            importedTasks = importFromCSV(data, context: context)
        }
        
        try? context.save()
        return importedTasks
    }
    
    private func exportToJSON(_ tasks: [TaskItem]) -> Data? {
        let tasksData = tasks.map { taskToDict($0) }
        return try? JSONSerialization.data(withJSONObject: tasksData, options: [.prettyPrinted, .sortedKeys])
    }
    
    private func exportToCSV(_ tasks: [TaskItem]) -> Data? {
        var csv = "ID,Title,Notes,Due Date,Priority,Status,Project,Tags,Completed\n"
        
        for task in tasks {
            let row = [
                task.id.uuidString,
                escapeCSV(task.title),
                escapeCSV(task.notes),
                task.dueDate?.formatted() ?? "",
                task.priorityValue.name,
                task.statusValue.name,
                task.project?.name ?? "",
                task.tags.map { $0.name }.joined(separator: ";"),
                task.isCompleted ? "Yes" : "No"
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv.data(using: .utf8)
    }
    
    private func taskToDict(_ task: TaskItem) -> [String: Any] {
        return [
            "id": task.id.uuidString,
            "title": task.title,
            "notes": task.notes,
            "dueDate": task.dueDate?.ISO8601Format() ?? "",
            "priority": task.priorityValue.name,
            "status": task.statusValue.name,
            "isCompleted": task.isCompleted,
            "project": task.project?.name ?? "",
            "tags": task.tags.map { $0.name }
        ]
    }
    
    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"" + string.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return string
    }
    
    private func importFromJSON(_ data: Data, context: ModelContext) -> [TaskItem] {
        guard let tasksData = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        
        var importedTasks: [TaskItem] = []
        
        for taskData in tasksData {
            let task = TaskItem(
                title: taskData["title"] as? String ?? "Untitled",
                notes: taskData["notes"] as? String ?? ""
            )
            
            if let priorityString = taskData["priority"] as? String,
               let priority = Priority.allCases.first(where: { $0.name == priorityString }) {
                task.priorityValue = priority
            }
            
            if let statusString = taskData["status"] as? String,
               let status = TaskStatus.allCases.first(where: { $0.name == statusString }) {
                task.statusValue = status
            }
            
            if let dueDateString = taskData["dueDate"] as? String, !dueDateString.isEmpty,
               let dueDate = ISO8601DateFormatter().date(from: dueDateString) {
                task.dueDate = dueDate
            }

            if let isCompleted = taskData["isCompleted"] as? Bool, isCompleted {
                task.isCompleted = true
            }

            context.insert(task)
            importedTasks.append(task)
        }

        return importedTasks
    }

    private func importFromCSV(_ data: Data, context: ModelContext) -> [TaskItem] {
        guard let csvString = String(data: data, encoding: .utf8) else {
            return []
        }

        let lines = csvString.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard lines.count > 1 else { return [] }

        var importedTasks: [TaskItem] = []

        // Column order matches exportToCSV:
        // ID,Title,Notes,Due Date,Priority,Status,Project,Tags,Completed
        for line in lines.dropFirst() {
            let columns = parseCSVLine(line)
            guard columns.count >= 2 else { continue }

            let task = TaskItem(title: columns[1])
            if columns.count > 2 {
                task.notes = columns[2]
            }
            if columns.count > 4,
               let priority = Priority.allCases.first(where: { $0.name == columns[4] }) {
                task.priorityValue = priority
            }
            if columns.count > 5,
               let status = TaskStatus.allCases.first(where: { $0.name == columns[5] }) {
                task.statusValue = status
            }
            if columns.count > 8, columns[8].caseInsensitiveCompare("Yes") == .orderedSame {
                task.isCompleted = true
            }

            context.insert(task)
            importedTasks.append(task)
        }

        return importedTasks
    }

    /// Parses a single CSV line into its fields, honouring the same quoting
    /// rules produced by `escapeCSV` (double quotes wrap fields containing
    /// commas/quotes/newlines, and literal quotes are doubled). A naive
    /// `components(separatedBy: ",")` split would corrupt any exported field
    /// that contained a comma.
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var insideQuotes = false
        var iterator = line.makeIterator()
        var pending: Character? = iterator.next()

        while let char = pending {
            pending = iterator.next()

            if insideQuotes {
                if char == "\"" {
                    if pending == "\"" {
                        // Escaped quote inside a quoted field.
                        current.append("\"")
                        pending = iterator.next()
                    } else {
                        insideQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else if char == "\"" {
                insideQuotes = true
            } else if char == "," {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }

        fields.append(current)
        return fields
    }
}

enum ExportFormat {
    case json
    case csv
}

enum ImportFormat {
    case json
    case csv
}
