import Foundation
import SwiftData

@MainActor
class CommentService {
    static let shared = CommentService()
    
    func addComment(to task: TaskItem, content: String, userName: String = "Nathan BUISSON", context: ModelContext) -> Comment {
        let comment = Comment(content: content, userName: userName)
        comment.task = task
        task.comments.append(comment)
        
        logActivity(for: task, action: "comment_added", description: "Added comment", context: context)
        try? context.save()
        
        return comment
    }
    
    func updateComment(_ comment: Comment, content: String, context: ModelContext) {
        comment.content = content
        comment.isEdited = true
        comment.updatedAt = Date()
        try? context.save()
    }
    
    func deleteComment(_ comment: Comment, context: ModelContext) {
        context.delete(comment)
        try? context.save()
    }
    
    private func logActivity(for task: TaskItem, action: String, description: String, context: ModelContext) {
        let log = ActivityLog(action: action, activityDescription: description, userName: "Nathan BUISSON")
        log.task = task
        task.activityLogs.append(log)
    }
}
