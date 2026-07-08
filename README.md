# planX

A native macOS task manager built with SwiftUI and SwiftData.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-native-green)

## Features

### Kanban Board
- Four columns: To Do, In Progress, Waiting, Done
- Drag and drop tasks between columns
- Cards show due date, priority, project, subtask progress, and active timer
- Click subtasks directly on cards to toggle completion
- Per-task option to show notes on the card
- Multi-select and bulk delete

### Task Detail
- Title, status, priority, due date, start date
- Subtasks with inline editing and progress tracking
- Tags and project assignment
- Rich notes editor
- Time tracking with start/stop timer
- Task dependencies (blocks / blocked by / related)

### Graph View
- Visualize tasks and their dependency links
- Hierarchical layout based on dependency depth
- Drag nodes to reposition
- Pan and zoom
- Color-coded arrows (blocks = red, related = blue)

### Sidebar
- Filter by project or tag
- Task counts per project
- Quick-add projects and tags

### Other
- Full-text search across tasks and notes
- Sort by due date, priority, title, or created date
- Quick Add (natural language) or full form task creation
- Dark mode support

## Quick Add Syntax

```
Finish tax documents tomorrow high #admin
```

Parsed as: title "Finish tax documents", due tomorrow, high priority, tag "admin".

- Dates: `today`, `tomorrow`, `next week`, `YYYY-MM-DD`
- Priority: `low`, `medium`, `high`
- Tags: `#tagname`
- Projects: `@projectname`

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| New Task | ⌘N |
| Select All | ⌘A (select mode) |

## Installation

1. Download `planX.dmg` from [Releases](../../releases)
2. Open the DMG and drag planX to Applications
3. Right-click → Open on first launch (app is unsigned)

## Building from Source

Requires Xcode 15+ and macOS 14+.

```bash
git clone https://github.com/NathBuiss/planX
open planX/planX.xcodeproj
```

Press `⌘R` to build and run.

## Tech Stack

- **SwiftUI** — UI framework
- **SwiftData** — persistence
- **Canvas API** — graph view rendering
- **AppKit** — native macOS integration

## License

MIT
