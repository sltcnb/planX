import Foundation
import SwiftData
import Combine

@MainActor
class AppViewModel: ObservableObject {
    @Published var selectedNavigationItem: NavigationItem = .today
    @Published var selectedTask: TaskItem?
    @Published var selectedProject: Project?
    @Published var selectedTag: Tag?
    @Published var searchText: String = ""
    @Published var isSidebarVisible: Bool = true
    @Published var showQuickAdd: Bool = false
    
    @Published var tasks: [TaskItem] = []
    @Published var projects: [Project] = []
    @Published var tags: [Tag] = []
    
    @Published var filterPriority: Priority? = nil
    @Published var filterStatus: TaskStatus? = nil
    @Published var sortOrder: SortOrder = .dueDate
    @Published var isSelectMode: Bool = false
    @Published var selectedTaskIDs: Set<UUID> = []
    @Published var refreshToken: UUID = UUID()

    enum SortOrder {
        case dueDate, priority, title, createdAt
    }
    
    var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func loadTasks() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<TaskItem>(
                sortBy: [SortDescriptor(\.dueDate), SortDescriptor(\.priority, order: .reverse)]
            )
            tasks = try context.fetch(descriptor)
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    func loadProjects() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.name)])
            projects = try context.fetch(descriptor)
        } catch {
            print("Error loading projects: \(error)")
        }
    }
    
    func loadTags() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
            tags = try context.fetch(descriptor)
        } catch {
            print("Error loading tags: \(error)")
        }
    }
    
    func refresh() {
        loadTasks()
        loadProjects()
        loadTags()
        refreshToken = UUID()
    }
    
    func getFilteredTasks() -> [TaskItem] {
        // modelContext nil = deleted; guard before any property access
        var filtered = tasks.filter {
            guard $0.modelContext != nil else { return false }
            return true
        }

        if let project = selectedProject {
            filtered = filtered.filter { $0.project?.id == project.id }
        }
        if let tag = selectedTag {
            filtered = filtered.filter { $0.tags.contains { $0.id == tag.id } }
        }
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.notes.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOrder {
        case .dueDate:
            filtered.sort {
                let a = $0.dueDate ?? .distantFuture
                let b = $1.dueDate ?? .distantFuture
                return a < b
            }
        case .priority:
            filtered.sort { $0.priority > $1.priority }
        case .title:
            filtered.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .createdAt:
            filtered.sort { $0.createdAt > $1.createdAt }
        }

        return filtered
    }
}

enum NavigationItem: Identifiable, Hashable {
    case today
    case upcoming
    case inbox
    case projects
    case tags
    case completed
    
    var id: Int {
        switch self {
        case .today: return 0
        case .upcoming: return 1
        case .inbox: return 2
        case .projects: return 3
        case .tags: return 4
        case .completed: return 5
        }
    }
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .inbox: return "Inbox"
        case .projects: return "Projects"
        case .tags: return "Tags"
        case .completed: return "Completed"
        }
    }
    
    var icon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .upcoming: return "calendar"
        case .inbox: return "tray"
        case .projects: return "folder.fill"
        case .tags: return "tag.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}
