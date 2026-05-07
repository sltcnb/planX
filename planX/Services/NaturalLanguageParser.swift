import Foundation

struct ParsedTaskInfo {
    var title: String
    var dueDate: Date?
    var priority: Priority = .medium
    var tags: [String] = []
    var project: String?
}

class NaturalLanguageParser {
    
    static func parse(_ input: String) -> ParsedTaskInfo {
        var title = input
        var dueDate: Date?
        var priority = Priority.medium
        var tags: [String] = []
        var project: String?
        
        let calendar = Calendar.current
        let now = Date()
        
        let components = title.split(separator: " ")
        var indicesToRemove: [Int] = []
        
        for (index, component) in components.enumerated() {
            let lower = component.lowercased()
            
            if lower.hasPrefix("#") {
                let tagName = String(lower.dropFirst())
                if !tagName.isEmpty {
                    tags.append(tagName)
                    indicesToRemove.append(index)
                }
            }
            
            if lower.hasPrefix("@") {
                let projectName = String(lower.dropFirst())
                if !projectName.isEmpty {
                    project = projectName
                    indicesToRemove.append(index)
                }
            }
            
            switch lower {
            case "today":
                dueDate = now
                indicesToRemove.append(index)
            case "tomorrow":
                dueDate = calendar.date(byAdding: .day, value: 1, to: now)
                indicesToRemove.append(index)
            case "next", "week":
                if index + 1 < components.count && components[index + 1].lowercased() == "week" {
                    dueDate = calendar.date(byAdding: .weekOfYear, value: 1, to: now)
                    indicesToRemove.append(index)
                    indicesToRemove.append(index + 1)
                }
            case "high":
                priority = .high
                indicesToRemove.append(index)
            case "medium":
                priority = .medium
                indicesToRemove.append(index)
            case "low":
                priority = .low
                indicesToRemove.append(index)
            default:
                if let date = parseDate(String(component)) {
                    dueDate = date
                    indicesToRemove.append(index)
                }
            }
        }
        
        let filteredComponents = components.enumerated()
            .filter { !indicesToRemove.contains($0.offset) }
            .map { String($0.element) }
        
        title = filteredComponents.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        
        return ParsedTaskInfo(
            title: title,
            dueDate: dueDate,
            priority: priority,
            tags: tags,
            project: project
        )
    }
    
    private static func parseDate(_ string: String) -> Date? {
        let formatters: [DateFormatter] = [
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "MM/dd/yyyy"
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "dd/MM/yyyy"
                return f
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        return nil
    }
}
