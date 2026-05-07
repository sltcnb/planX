import Foundation
import SwiftData

@MainActor
class QuickAddViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var parsedInfo: ParsedTaskInfo?
    @Published var isPresented: Bool = false
    
    var modelContext: ModelContext?
    var onTaskAdded: (() -> Void)?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func parseInput() {
        if inputText.isEmpty {
            parsedInfo = nil
            return
        }
        
        parsedInfo = NaturalLanguageParser.parse(inputText)
    }
    
    func addTask() {
        guard let context = modelContext, let info = parsedInfo, !info.title.isEmpty else { return }
        
        let task = TaskItem(
            title: info.title,
            notes: "",
            dueDate: info.dueDate,
            priority: info.priority
        )
        
        if !info.tags.isEmpty {
            var tags: [Tag] = []
            for tagName in info.tags {
                let descriptor = FetchDescriptor<Tag>()
                let allTags = try? context.fetch(descriptor)
                let existingTag = allTags?.first { $0.name.caseInsensitiveCompare(tagName) == .orderedSame }
                
                if let tag = existingTag {
                    tags.append(tag)
                } else {
                    let newTag = Tag(name: tagName)
                    context.insert(newTag)
                    tags.append(newTag)
                }
            }
            task.tags = tags
        }
        
        if let projectName = info.project {
            let descriptor = FetchDescriptor<Project>()
            let allProjects = try? context.fetch(descriptor)
            let existingProject = allProjects?.first { $0.name.caseInsensitiveCompare(projectName) == .orderedSame }
            
            if let project = existingProject {
                task.project = project
            } else {
                let newProject = Project(name: projectName)
                context.insert(newProject)
                task.project = newProject
            }
        }
        
        context.insert(task)
        try? context.save()
        
        inputText = ""
        parsedInfo = nil
        isPresented = false
        onTaskAdded?()
    }
}
