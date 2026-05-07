import Foundation
import SwiftData

struct PreviewData {
    static let shared = PreviewData()
    
    var modelContainer: ModelContainer {
        do {
            let schema = Schema([
                TaskItem.self,
                Subtask.self,
                Project.self,
                Tag.self
            ])
            
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            // Add sample data for previews
            let context = ModelContext(container)
            SampleDataGenerator.generateSampleData(in: context)
            
            return container
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }
}
