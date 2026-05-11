import SwiftUI
import SwiftData

// Value-type snapshots — never hold live SwiftData objects in @State
private struct DepEdge {
    let predID: UUID
    let succID: UUID
    let type: String
}

fileprivate struct TaskSnapshot: Identifiable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let statusValue: TaskStatus
    let priorityValue: Priority
    let projectName: String?
    let projectColor: String?
    let tagNames: [String]
    let dueDate: Date?
}

struct TaskGraphView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var selectedTask: TaskItem?
    @Environment(\.modelContext) private var modelContext

    @State private var nodePositions: [UUID: CGPoint] = [:]
    @State private var scale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var panStart: CGSize = .zero
    @State private var depEdges: [DepEdge] = []
    @State private var snapshots: [TaskSnapshot] = []
    @State private var dragStarts: [UUID: CGPoint] = [:]
    @State private var isDraggingNode = false
    @State private var laneLabels: [(key: String, label: String, y: CGFloat)] = []

    private var connectedIDs: Set<UUID> {
        var ids = Set<UUID>()
        for e in depEdges { ids.insert(e.predID); ids.insert(e.succID) }
        return ids
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(NSColor.underPageBackgroundColor)

                if depEdges.isEmpty && snapshots.isEmpty {
                    emptyState
                } else {
                    edgeCanvas
                    laneLayer
                    nodeLayer
                    if !depEdges.isEmpty {
                        legendView
                            .padding(12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                }
            }
            .gesture(MagnificationGesture()
                .onChanged { val in scale = max(0.3, min(2.5, val)) }
            )
            .simultaneousGesture(DragGesture()
                .onChanged { val in
                    guard !isDraggingNode else { return }
                    panOffset = CGSize(
                        width: panStart.width + val.translation.width,
                        height: panStart.height + val.translation.height
                    )
                }
                .onEnded { val in
                    guard !isDraggingNode else { return }
                    panStart = panOffset
                }
            )
            .onAppear {
                loadSnapshots()
                layoutNodes(in: geo.size)
            }
            .onChange(of: viewModel.tasks.count) {
                loadSnapshots()
                layoutNodes(in: geo.size)
            }
        }
    }

    // MARK: - Subviews

    private var edgeCanvas: some View {
        Canvas { ctx, size in
            // Lane separator lines
            for (i, lane) in laneLabels.enumerated() where i > 0 {
                let lineY = applyTransform(CGPoint(x: 0, y: lane.y - 14)).y
                var path = Path()
                path.move(to: CGPoint(x: 0, y: lineY))
                path.addLine(to: CGPoint(x: size.width, y: lineY))
                ctx.stroke(path, with: .color(.secondary.opacity(0.15)), lineWidth: 1)
            }
            // Dependency arrows
            for edge in depEdges {
                guard let fromPos = nodePositions[edge.predID],
                      let toPos   = nodePositions[edge.succID]
                else { continue }
                drawArrow(
                    ctx: ctx,
                    from: applyTransform(fromPos),
                    to: applyTransform(toPos),
                    color: depColor(edge.type)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var nodeLayer: some View {
        ForEach(snapshots) { snap in
            if let pos = nodePositions[snap.id] {
                TaskNodeView(
                    snapshot: snap,
                    isIsolated: !connectedIDs.contains(snap.id),
                    isSelected: selectedTask?.modelContext != nil && selectedTask?.id == snap.id
                )
                .position(applyTransform(pos))
                .onTapGesture {
                    guard let live = viewModel.tasks.first(where: { $0.id == snap.id }),
                          live.modelContext != nil else { return }
                    selectedTask = live
                }
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            isDraggingNode = true
                            let start = dragStarts[snap.id] ?? pos
                            if dragStarts[snap.id] == nil { dragStarts[snap.id] = pos }
                            nodePositions[snap.id] = CGPoint(
                                x: start.x + val.translation.width / scale,
                                y: start.y + val.translation.height / scale
                            )
                        }
                        .onEnded { _ in
                            isDraggingNode = false
                            dragStarts.removeValue(forKey: snap.id)
                        }
                )
            }
        }
    }

    private var laneLayer: some View {
        ForEach(Array(laneLabels.enumerated()), id: \.offset) { _, lane in
            Text(lane.label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
                .position(applyTransform(CGPoint(x: 10, y: lane.y)))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No dependencies")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Add dependencies between tasks to visualize their relationships.")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 1).fill(Color.red.opacity(0.7)).frame(width: 16, height: 2)
                Text("Blocks").font(.caption).foregroundColor(.secondary)
            }
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 1).fill(Color.blue.opacity(0.7)).frame(width: 16, height: 2)
                Text("Related").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }

    // MARK: - Data

    private func loadSnapshots() {
        let liveTasks = viewModel.getFilteredTasks()

        // Build snapshots and a PersistentIdentifier→UUID map from known-valid tasks.
        // Never access @PersistedProperty on objects that might be invalidated.
        var pidToUUID: [PersistentIdentifier: UUID] = [:]
        snapshots = liveTasks.compactMap { task in
            guard task.modelContext != nil else { return nil }
            pidToUUID[task.persistentModelID] = task.id
            return TaskSnapshot(
                id: task.id,
                title: task.title,
                isCompleted: task.isCompleted,
                statusValue: task.statusValue,
                priorityValue: task.priorityValue,
                projectName: task.project?.name,
                projectColor: task.project?.color,
                tagNames: task.tags.map { $0.name },
                dueDate: task.dueDate
            )
        }

        do {
            let raw = try modelContext.fetch(FetchDescriptor<TaskDependency>())
            depEdges = raw.compactMap { dep in
                // Use persistentModelID (backed by NSManagedObject.objectID — safe on
                // faulted/invalidated objects, unlike @PersistedProperty accessors).
                // If either task no longer exists in our valid set, the dict lookup
                // returns nil and the dep is dropped — no backing-data access needed.
                guard let predPID = dep.predecessor?.persistentModelID,
                      let succPID = dep.successor?.persistentModelID,
                      let predID  = pidToUUID[predPID],
                      let succID  = pidToUUID[succPID]
                else { return nil }
                return DepEdge(predID: predID, succID: succID, type: dep.relationshipType)
            }
        } catch {}
    }

    // MARK: - Layout

    private func layoutNodes(in size: CGSize) {
        let nodeW: CGFloat = 170
        let nodeH: CGFloat = 80
        let colGap: CGFloat = 30
        let rowGap: CGFloat = 14
        let laneGap: CGFloat = 44
        let labelH: CGFloat = 18
        let leftPad: CGFloat = 60

        // Precompute depth for all nodes
        var depthMap: [UUID: Int] = [:]
        for snap in snapshots {
            if depthMap[snap.id] == nil {
                var visited = Set<UUID>()
                depthMap[snap.id] = computeDepth(id: snap.id, visited: &visited)
            }
        }

        // Group by project; secondary sort by first tag within each group
        var byProject: [String: [TaskSnapshot]] = [:]
        for snap in snapshots {
            byProject[snap.projectName ?? "", default: []].append(snap)
        }
        let sortedKeys = byProject.keys.sorted { a, b in
            if a.isEmpty { return false }  // "No Project" last
            if b.isEmpty { return true }
            return a < b
        }

        var currentY: CGFloat = 20
        var newLabels: [(key: String, label: String, y: CGFloat)] = []

        for key in sortedKeys {
            // Secondary sort within lane: by first tag name, then title
            let snapsInLane = (byProject[key] ?? []).sorted {
                let ta = $0.tagNames.first ?? ""
                let tb = $1.tagNames.first ?? ""
                return ta == tb ? $0.title < $1.title : ta < tb
            }

            let label = key.isEmpty ? "No Project" : key
            newLabels.append((key: key, label: label, y: currentY + labelH / 2))
            currentY += labelH + 6

            let connected = snapsInLane.filter { connectedIDs.contains($0.id) }
            let isolated  = snapsInLane.filter { !connectedIDs.contains($0.id) }

            // Connected: depth columns, secondary sort by tag within column
            var byDepth: [Int: [TaskSnapshot]] = [:]
            for snap in connected {
                byDepth[depthMap[snap.id] ?? 0, default: []].append(snap)
            }

            var maxRowCount = 0
            for (depth, col) in byDepth.sorted(by: { $0.key < $1.key }) {
                for (row, snap) in col.enumerated() {
                    let x = CGFloat(depth) * (nodeW + colGap) + nodeW / 2 + leftPad
                    let y = currentY + CGFloat(row) * (nodeH + rowGap) + nodeH / 2
                    nodePositions[snap.id] = CGPoint(x: x, y: y)
                }
                maxRowCount = max(maxRowCount, col.count)
            }

            // Isolated: compact grid continuing after connected columns
            let maxDepth = byDepth.keys.max() ?? -1
            let isoX0 = CGFloat(maxDepth + 1) * (nodeW + colGap) + nodeW / 2 + leftPad
            let isoCols = max(1, Int(ceil(sqrt(Double(max(1, isolated.count))))))
            let isoGap: CGFloat = 12
            for (i, snap) in isolated.enumerated() {
                let col = i % isoCols
                let row = i / isoCols
                let x = isoX0 + CGFloat(col) * (nodeW + isoGap)
                let y = currentY + CGFloat(row) * (nodeH + isoGap) + nodeH / 2
                nodePositions[snap.id] = CGPoint(x: x, y: y)
                maxRowCount = max(maxRowCount, row + 1)
            }

            currentY += CGFloat(max(1, maxRowCount)) * (nodeH + rowGap) + laneGap
        }

        laneLabels = newLabels
    }

    private func computeDepth(id: UUID, visited: inout Set<UUID>) -> Int {
        guard !visited.contains(id) else { return 0 }
        visited.insert(id)
        let predecessorIDs = depEdges.filter { $0.succID == id }.map { $0.predID }
        if predecessorIDs.isEmpty { return 0 }
        return 1 + (predecessorIDs.map { computeDepth(id: $0, visited: &visited) }.max() ?? 0)
    }

    // MARK: - Drawing

    private func applyTransform(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x * scale + panOffset.width, y: p.y * scale + panOffset.height)
    }

    private func depColor(_ type: String) -> Color {
        switch type {
        case "blocks":  return .red.opacity(0.7)
        case "related": return .blue.opacity(0.7)
        default:        return .secondary.opacity(0.5)
        }
    }

    private func drawArrow(ctx: GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        let dx = to.x - from.x, dy = to.y - from.y
        let len = sqrt(dx * dx + dy * dy)
        guard len > 1 else { return }
        let ux = dx / len, uy = dy / len
        let arrowLen: CGFloat = 9, nodeR: CGFloat = 28

        let start = CGPoint(x: from.x + ux * nodeR, y: from.y + uy * nodeR)
        let end   = CGPoint(x: to.x   - ux * nodeR, y: to.y   - uy * nodeR)

        var line = Path()
        line.move(to: start); line.addLine(to: end)
        ctx.stroke(line, with: .color(color), lineWidth: 1.5)

        let angle = atan2(uy, ux)
        var head = Path()
        head.move(to: end)
        head.addLine(to: CGPoint(x: end.x + cos(angle + .pi * 5/6) * arrowLen,
                                 y: end.y + sin(angle + .pi * 5/6) * arrowLen))
        head.addLine(to: CGPoint(x: end.x + cos(angle - .pi * 5/6) * arrowLen,
                                 y: end.y + sin(angle - .pi * 5/6) * arrowLen))
        head.closeSubpath()
        ctx.fill(head, with: .color(color))
    }
}

// MARK: - Node View

fileprivate struct TaskNodeView: View {
    let snapshot: TaskSnapshot
    let isIsolated: Bool
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title row
            HStack(spacing: 5) {
                Image(systemName: snapshot.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 10))
                    .foregroundColor(snapshot.isCompleted ? .green : .secondary)
                Text(snapshot.title.isEmpty ? "Untitled" : snapshot.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                    .foregroundColor(isIsolated ? .secondary : .primary)
                Spacer(minLength: 0)
                priorityDot
            }

            // Project row
            if let name = snapshot.projectName {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: snapshot.projectColor ?? "blue"))
                        .frame(width: 5, height: 5)
                    Text(name)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            // Tags row
            if !snapshot.tagNames.isEmpty {
                HStack(spacing: 3) {
                    ForEach(snapshot.tagNames.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 8))
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(3)
                    }
                    if snapshot.tagNames.count > 3 {
                        Text("+\(snapshot.tagNames.count - 3)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Due date row
            if let due = snapshot.dueDate {
                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.system(size: 8))
                    Text(formatDue(due))
                        .font(.system(size: 8))
                }
                .foregroundColor(due < Date() && !snapshot.isCompleted ? .red : .secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: isIsolated ? 150 : 170)
        .background(Color(NSColor.controlBackgroundColor).opacity(isIsolated ? 0.6 : 1.0))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? Color.accentColor : (isIsolated ? statusColor.opacity(0.4) : statusColor),
                    lineWidth: isSelected ? 2 : 1.5
                )
        )
        .cornerRadius(8)
        .shadow(color: .black.opacity(isSelected ? 0.25 : 0.1), radius: isSelected ? 5 : 2, x: 0, y: 1)
    }

    private func formatDue(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }

    private var statusColor: Color {
        switch snapshot.statusValue {
        case .notStarted: return .secondary.opacity(0.5)
        case .inProgress: return .blue
        case .waiting:    return .orange
        case .done:       return .green
        }
    }

    @ViewBuilder private var priorityDot: some View {
        switch snapshot.priorityValue {
        case .high:   Circle().fill(Color.red).frame(width: 6, height: 6)
        case .medium: Circle().fill(Color.orange).frame(width: 6, height: 6)
        case .low:    EmptyView()
        }
    }
}
