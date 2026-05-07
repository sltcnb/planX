import Foundation
import SwiftData
import UniformTypeIdentifiers

@MainActor
class AttachmentService {
    static let shared = AttachmentService()
    
    func addAttachment(to task: TaskItem, data: Data, name: String, mimeType: String, context: ModelContext) -> Attachment {
        let attachment = Attachment(
            name: name,
            data: data,
            mimeType: mimeType
        )
        attachment.task = task
        task.attachments.append(attachment)
        
        logActivity(for: task, action: "attachment_added", description: "Added attachment: \(name)", context: context)
        try? context.save()
        
        return attachment
    }
    
    func addFileAttachment(to task: TaskItem, fileURL: URL, context: ModelContext) -> Attachment? {
        let name = fileURL.lastPathComponent
        let mimeType = UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        
        do {
            let data = try Data(contentsOf: fileURL)
            return addAttachment(to: task, data: data, name: name, mimeType: mimeType, context: context)
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
    }
    
    func deleteAttachment(_ attachment: Attachment, context: ModelContext) {
        guard let task = attachment.task else { return }
        
        let name = attachment.name
        context.delete(attachment)
        logActivity(for: task, action: "attachment_removed", description: "Removed attachment: \(name)", context: context)
        try? context.save()
    }
    
    func getAttachmentSize(_ attachment: Attachment) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: attachment.fileSize)
    }
    
    func exportAttachment(_ attachment: Attachment) -> URL? {
        guard let data = attachment.data else { return nil }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(attachment.name)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error exporting attachment: \(error)")
            return nil
        }
    }
    
    private func logActivity(for task: TaskItem, action: String, description: String, context: ModelContext) {
        let log = ActivityLog(action: action, activityDescription: description, userName: "Nathan BUISSON")
        log.task = task
        task.activityLogs.append(log)
    }
}
