import Foundation
import SwiftData

@Model
final class Attachment {
    var id: UUID
    var name: String
    var fileURL: String?
    var data: Data?
    var mimeType: String
    var fileSize: Int64
    
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .nullify)
    var task: TaskItem?
    
    init(id: UUID = UUID(), name: String, fileURL: String? = nil, data: Data? = nil, mimeType: String = "application/octet-stream") {
        self.id = id
        self.name = name
        self.fileURL = fileURL
        self.data = data
        self.mimeType = mimeType
        self.fileSize = Int64(data?.count ?? 0)
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
