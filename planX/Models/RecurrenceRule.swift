import Foundation
import SwiftData

@Model
final class RecurrenceRule {
    var id: UUID
    var frequency: String // daily, weekly, monthly, yearly
    var interval: Int
    var endDate: Date?
    var count: Int?
    
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .nullify)
    var parentTask: TaskItem?
    
    init(id: UUID = UUID(), frequency: String, interval: Int = 1, endDate: Date? = nil, count: Int? = nil) {
        self.id = id
        self.frequency = frequency
        self.interval = interval
        self.endDate = endDate
        self.count = count
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func nextOccurrence(from date: Date) -> Date? {
        var components = DateComponents()
        
        switch frequency {
        case "daily":
            components.day = interval
        case "weekly":
            components.weekOfYear = interval
        case "monthly":
            components.month = interval
        case "yearly":
            components.year = interval
        default:
            return nil
        }
        
        return Calendar.current.date(byAdding: components, to: date)
    }
}
