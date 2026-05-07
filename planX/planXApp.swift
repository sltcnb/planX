import SwiftUI
import SwiftData

@main
struct planXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            Subtask.self,
            Project.self,
            Tag.self,
            Attachment.self,
            RecurrenceRule.self,
            TaskDependency.self,
            ActivityLog.self,
            TimeEntry.self,
            Comment.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            return container
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
                .modelContainer(sharedModelContainer)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Quick Add") {
                    NotificationCenter.default.post(name: .newTask, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                Button("Full Form") {
                    NotificationCenter.default.post(name: .newFullFormTask, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            CommandMenu("View") {
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
                
                Divider()
                
                Button("Today") {
                    NotificationCenter.default.post(name: .goToToday, object: nil)
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Upcoming") {
                    NotificationCenter.default.post(name: .goToUpcoming, object: nil)
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Board") {
                    NotificationCenter.default.post(name: .goToBoard, object: nil)
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Calendar") {
                    NotificationCenter.default.post(name: .goToCalendar, object: nil)
                }
                .keyboardShortcut("4", modifiers: .command)
            }
            
            CommandMenu("Task") {
                Button("Mark Complete") {
                    NotificationCenter.default.post(name: .markComplete, object: nil)
                }
                .keyboardShortcut(.return, modifiers: .command)
                
                Button("Delete Task") {
                    NotificationCenter.default.post(name: .deleteTask, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

extension Notification.Name {
    static let newTask = Notification.Name("newTask")
    static let newFullFormTask = Notification.Name("newFullFormTask")
    static let goToCalendar = Notification.Name("goToCalendar")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let goToToday = Notification.Name("goToToday")
    static let goToUpcoming = Notification.Name("goToUpcoming")
    static let goToBoard = Notification.Name("goToBoard")
    static let markComplete = Notification.Name("markComplete")
    static let deleteTask = Notification.Name("deleteTask")
    static let search = Notification.Name("search")
}
