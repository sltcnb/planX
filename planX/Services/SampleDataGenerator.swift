import Foundation
import SwiftData

class SampleDataGenerator {
    static func generateSampleData(in context: ModelContext) {
        // Create sample projects
        let workProject = Project(name: "Work", taskDescription: "Work-related tasks", color: "blue")
        let personalProject = Project(name: "Personal", taskDescription: "Personal tasks", color: "green")
        let learningProject = Project(name: "Learning", taskDescription: "Learning and development", color: "purple")
        
        context.insert(workProject)
        context.insert(personalProject)
        context.insert(learningProject)
        
        // Create sample tags
        let urgentTag = Tag(name: "urgent", color: "red")
        let adminTag = Tag(name: "admin", color: "blue")
        let healthTag = Tag(name: "health", color: "green")
        let financeTag = Tag(name: "finance", color: "orange")
        
        context.insert(urgentTag)
        context.insert(adminTag)
        context.insert(healthTag)
        context.insert(financeTag)
        
        // Create sample tasks
        let calendar = Calendar.current
        let today = Date()
        
        // Today tasks
        let task1 = TaskItem(title: "Review quarterly report", notes: "Go through Q4 financial report and prepare feedback", dueDate: today, priority: .high)
        task1.project = workProject
        task1.tags = [urgentTag]
        context.insert(task1)
        
        let task2 = TaskItem(title: "Team standup meeting", notes: "Daily sync with the development team", dueDate: today, priority: .medium)
        task2.project = workProject
        task2.statusValue = .inProgress
        context.insert(task2)
        
        let task3 = TaskItem(title: "Pay electricity bill", notes: "Due today - check online banking", dueDate: today, priority: .medium)
        task3.project = personalProject
        task3.tags = [financeTag]
        context.insert(task3)
        
        // Tomorrow tasks
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let task4 = TaskItem(title: "Dentist appointment", notes: "Annual checkup at Dr. Smith's office", dueDate: tomorrow, priority: .high)
        task4.project = personalProject
        task4.tags = [healthTag]
        context.insert(task4)
        
        let task5 = TaskItem(title: "Complete Swift certification study", notes: "Finish module 5 - Advanced SwiftUI patterns", dueDate: tomorrow, priority: .medium)
        task5.project = learningProject
        context.insert(task5)
        
        // This week tasks
        let inTwoDays = calendar.date(byAdding: .day, value: 2, to: today)!
        
        let task6 = TaskItem(title: "Submit expense reports", notes: "Compile all receipts from business trip", dueDate: inTwoDays, priority: .medium)
        task6.project = workProject
        task6.tags = [adminTag, financeTag]
        context.insert(task6)
        
        let task7 = TaskItem(title: "Grocery shopping", notes: "Buy weekly groceries - check fridge first", dueDate: inTwoDays, priority: .low)
        task7.project = personalProject
        context.insert(task7)
        
        // Next week tasks
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: today)!
        
        let task8 = TaskItem(title: "Project presentation", notes: "Present Q1 roadmap to stakeholders", dueDate: nextWeek, priority: .high)
        task8.project = workProject
        task8.tags = [urgentTag]
        context.insert(task8)
        
        // Overdue task
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let task9 = TaskItem(title: "Send weekly status update", notes: "Email status report to manager", dueDate: yesterday, priority: .high)
        task9.project = workProject
        task9.statusValue = .waiting
        context.insert(task9)
        
        // No due date tasks
        let task10 = TaskItem(title: "Organize desk", notes: "Clean and organize workspace", priority: .low)
        task10.project = personalProject
        context.insert(task10)
        
        let task11 = TaskItem(title: "Read technical book", notes: "Continue reading 'Clean Architecture'", priority: .low)
        task11.project = learningProject
        context.insert(task11)
        
        // Add subtasks to some tasks
        let subtask1 = Subtask(title: "Gather all financial documents", notes: "Check email and shared drives")
        subtask1.parentTask = task1
        task1.subtasks.append(subtask1)
        
        let subtask2 = Subtask(title: "Review revenue section", notes: "Focus on Q4 performance")
        subtask2.parentTask = task1
        task1.subtasks.append(subtask2)
        
        let subtask3 = Subtask(title: "Review expenses section")
        subtask3.parentTask = task1
        task1.subtasks.append(subtask3)
        
        let subtask4 = Subtask(title: "Prepare summary notes")
        subtask4.parentTask = task1
        task1.subtasks.append(subtask4)
        subtask4.isCompleted = true
        
        let subtask5 = Subtask(title: "Buy milk")
        subtask5.parentTask = task7
        task7.subtasks.append(subtask5)
        
        let subtask6 = Subtask(title: "Buy eggs")
        subtask6.parentTask = task7
        task7.subtasks.append(subtask6)
        
        let subtask7 = Subtask(title: "Buy vegetables")
        subtask7.parentTask = task7
        task7.subtasks.append(subtask7)
        
        let subtask8 = Subtask(title: "Create presentation slides")
        subtask8.parentTask = task8
        task8.subtasks.append(subtask8)
        
        let subtask9 = Subtask(title: "Practice presentation")
        subtask9.parentTask = task8
        task8.subtasks.append(subtask9)
        
        // Completed task
        let completedTask = TaskItem(title: "Setup development environment", notes: "Install Xcode, Git, and other tools", priority: .medium)
        completedTask.project = learningProject
        completedTask.isCompleted = true
        completedTask.completedAt = calendar.date(byAdding: .day, value: -2, to: today)
        context.insert(completedTask)
        
        // Task with recurrence
        let recurringTask = TaskItem(title: "Weekly team meeting", notes: "Recurring every week", dueDate: today, priority: .medium)
        recurringTask.project = workProject
        let recurrenceRule = RecurrenceRule(frequency: "weekly", interval: 1)
        recurrenceRule.parentTask = recurringTask
        recurringTask.recurrenceRule = recurrenceRule
        context.insert(recurringTask)
        
        // Task with dependencies
        let taskA = TaskItem(title: "Design database schema", notes: "First task", dueDate: today, priority: .high)
        taskA.project = workProject
        context.insert(taskA)
        
        let taskB = TaskItem(title: "Implement database layer", notes: "Depends on design", dueDate: tomorrow, priority: .high)
        taskB.project = workProject
        context.insert(taskB)
        
        let dependency = TaskDependency(relationshipType: "blocks", predecessor: taskA, successor: taskB)
        taskA.dependencies.append(dependency)
        taskB.dependencies.append(dependency)
        
        // Task with time tracking
        let timeTask = TaskItem(title: "Write documentation", notes: "Track time on this", priority: .medium)
        timeTask.project = workProject
        context.insert(timeTask)
        
        let timeEntry = TimeEntry(
            startTime: calendar.date(byAdding: .hour, value: -2, to: today)!,
            endTime: calendar.date(byAdding: .hour, value: -1, to: today)!,
            duration: 3600,
            entryDescription: "Initial documentation"
        )
        timeEntry.task = timeTask
        timeTask.timeEntries.append(timeEntry)
        
        // Task with comments
        let commentTask = TaskItem(title: "Review pull request", notes: "Check the changes", priority: .medium)
        commentTask.project = workProject
        context.insert(commentTask)
        
        let comment1 = Comment(content: "Looking at it now", userName: "Nathan BUISSON")
        comment1.task = commentTask
        commentTask.comments.append(comment1)
        
        let comment2 = Comment(content: "Looks good, just a few minor suggestions", userName: "Nathan BUISSON")
        comment2.task = commentTask
        commentTask.comments.append(comment2)
        
        // Task with attachment (sample data)
        let attachmentTask = TaskItem(title: "Prepare quarterly report", notes: "Attach the template", priority: .high)
        attachmentTask.project = workProject
        context.insert(attachmentTask)
        
        let sampleData = "Sample attachment content".data(using: .utf8)!
        let attachment = Attachment(name: "template.txt", data: sampleData, mimeType: "text/plain")
        attachment.task = attachmentTask
        attachmentTask.attachments.append(attachment)
        
        // Activity logs
        let activityLog = ActivityLog(action: "created", activityDescription: "Task created", userName: "Nathan BUISSON")
        activityLog.task = task1
        task1.activityLogs.append(activityLog)
        
        // Save all data
        try? context.save()
        
        print("Sample data generated successfully!")
    }
}
