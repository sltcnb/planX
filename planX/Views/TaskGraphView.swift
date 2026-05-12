import SwiftUI
import SwiftData

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

    private var filterKey: String {
        let proj = viewModel.selectedProject?.id.uuidString ?? ""
        let tag  = viewModel.selectedTag?.id.uuidString ?? ""
        let fp   = viewModel.filterPriority.map { "\($0)" } ?? ""
        let fs   = viewModel.filterStatus.map { "\($0)" } ?? ""
        return "\(viewModel.refreshToken)-\(viewModel.selectedNavigationItem)-\(proj)-\(tag)-\(viewModel.searchText)-\(fp)-\(fs)"
    }

    private var connectedIDs: Set<UUID> {
        var ids = Set<UUID>()
        for e in depEdges { ids.insert(e.predID); ids.insert(e.succID) }
        return ids
    }

    // Tasks that have an unresolved "blocks" predecessor — not yet actionable
    private var blockedIDs: Set<UUID> {
        var ids = Set<UUID>()
        for e in depEdges where e.type == "blocks" { ids.insert(e.succID) }
        return ids
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(NSColor.underPageBackgroundColor)

                if snapshots.isEmpty {
                    emptyState
                } else {
                    edgeCanvas
                    nodeLayer
                    projectLegend
                    if !depEdges.isEmpty {
                        legendView
                            .padding(12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                }
            }
            .clipped()
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
                .onEnded { _ in
                    guard !isDraggingNode else { return }
                    panStart = panOffset
                }
            )
            .onAppear {
                loadSnapshots()
                layoutNodes(in: geo.size)
            }
            .onChange(of: filterKey) {
                loadSnapshots()
                layoutNodes(in: geo.size)
            }
        }
    }

    // MARK: - Subviews

    private var edgeCanvas: some View {
        Canvas { ctx, size in
            for edge in depEdges {
                guard let fromPos = nodePositions[edge.predID],
                      let toPos   = nodePositions[edge.succID]
                else { continue }
                drawArrow(
                    ctx: ctx,
                    from: applyTransform(fromPos),
                    to: applyTransform(toPos),
                    color: depColor(edge.type),
                    isBlocking: edge.type == "blocks" || edge.type == "enables"
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
                    isBlocked: blockedIDs.contains(snap.id),
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

    @ViewBuilder private var projectLegend: some View {
        let projects = projectsForLegend()
        if !projects.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                Text("Projects")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                ForEach(projects, id: \.name) { proj in
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: proj.color))
                            .frame(width: 8, height: 8)
                        Text(proj.name)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No active tasks")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Tasks appear here. Add dependencies to visualize relationships.")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 5) {
            legendRow(color: .red.opacity(0.75), label: "Blocks", dashed: false)
            legendRow(color: .green.opacity(0.7), label: "Enables", dashed: false)
            legendRow(color: .secondary.opacity(0.5), label: "Related", dashed: true)
            legendRow(color: .purple.opacity(0.5), label: "Duplicate", dashed: true)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }

    private func legendRow(color: Color, label: String, dashed: Bool) -> some View {
        HStack(spacing: 6) {
            Canvas { ctx, size in
                var path = Path()
                path.move(to: CGPoint(x: 0, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
                ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, dash: dashed ? [4, 3] : []))
            }
            .frame(width: 18, height: 8)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    private func projectsForLegend() -> [(name: String, color: String)] {
        var seen = Set<String>()
        var result: [(name: String, color: String)] = []
        for snap in snapshots {
            if let name = snap.projectName, let color = snap.projectColor, !seen.contains(name) {
                seen.insert(name)
                result.append((name: name, color: color))
            }
        }
        return result.sorted { $0.name < $1.name }
    }

    // MARK: - Data

    private func loadSnapshots() {
        let liveTasks = viewModel.getFilteredTasks()
        var pidToUUID: [PersistentIdentifier: UUID] = [:]
        snapshots = liveTasks.compactMap { task in
            guard task.modelContext != nil, task.statusValue != .done else { return nil }
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
        let nodeW: CGFloat = 160
        let nodeH: CGFloat = 88
        let colGap: CGFloat = 44
        let rowGap: CGFloat = 18
        let topPad: CGFloat = 30
        let leftPad: CGFloat = 40

        var depthMap: [UUID: Int] = [:]
        for snap in snapshots {
            if depthMap[snap.id] == nil {
                var visited = Set<UUID>()
                depthMap[snap.id] = computeDepth(id: snap.id, visited: &visited)
            }
        }

        let connected = snapshots.filter { connectedIDs.contains($0.id) }
        let isolated  = snapshots.filter { !connectedIDs.contains($0.id) }

        let projectSort: (TaskSnapshot, TaskSnapshot) -> Bool = { a, b in
            let pa = a.projectName ?? "zzz"
            let pb = b.projectName ?? "zzz"
            return pa == pb ? a.title < b.title : pa < pb
        }

        if connected.isEmpty {
            // No deps — grid layout
            let cols = max(1, Int(ceil(sqrt(Double(snapshots.count)))))
            for (i, snap) in snapshots.sorted(by: projectSort).enumerated() {
                let col = i % cols
                let row = i / cols
                nodePositions[snap.id] = CGPoint(
                    x: leftPad + CGFloat(col) * (nodeW + colGap) + nodeW / 2,
                    y: topPad + CGFloat(row) * (nodeH + rowGap) + nodeH / 2
                )
            }
        } else {
            // Depth columns for connected nodes
            var byDepth: [Int: [TaskSnapshot]] = [:]
            for snap in connected {
                byDepth[depthMap[snap.id] ?? 0, default: []].append(snap)
            }
            for key in byDepth.keys {
                byDepth[key]!.sort(by: projectSort)
            }
            for (depth, snaps) in byDepth {
                for (row, snap) in snaps.enumerated() {
                    nodePositions[snap.id] = CGPoint(
                        x: leftPad + CGFloat(depth) * (nodeW + colGap) + nodeW / 2,
                        y: topPad + CGFloat(row) * (nodeH + rowGap) + nodeH / 2
                    )
                }
            }

            // Isolated: rightmost column
            let isoColX = leftPad + CGFloat((byDepth.keys.max() ?? -1) + 1) * (nodeW + colGap) + nodeW / 2
            for (i, snap) in isolated.sorted(by: projectSort).enumerated() {
                nodePositions[snap.id] = CGPoint(
                    x: isoColX,
                    y: topPad + CGFloat(i) * (nodeH + rowGap) + nodeH / 2
                )
            }
        }
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
        case "blocks":    return .red.opacity(0.75)
        case "enables":   return .green.opacity(0.7)
        case "related":   return .secondary.opacity(0.5)
        case "duplicate": return .purple.opacity(0.5)
        default:          return .secondary.opacity(0.4)
        }
    }

    private func drawArrow(ctx: GraphicsContext, from: CGPoint, to: CGPoint, color: Color, isBlocking: Bool) {
        let dx = to.x - from.x, dy = to.y - from.y
        let len = sqrt(dx * dx + dy * dy)
        guard len > 1 else { return }
        let ux = dx / len, uy = dy / len
        let arrowLen: CGFloat = 9, nodeR: CGFloat = 28

        let start = CGPoint(x: from.x + ux * nodeR, y: from.y + uy * nodeR)
        let end   = CGPoint(x: to.x   - ux * nodeR, y: to.y   - uy * nodeR)

        let cp1 = CGPoint(x: start.x + (end.x - start.x) * 0.45, y: start.y)
        let cp2 = CGPoint(x: end.x   - (end.x - start.x) * 0.45, y: end.y)

        var curve = Path()
        curve.move(to: start)
        curve.addCurve(to: end, control1: cp1, control2: cp2)
        let style = StrokeStyle(
            lineWidth: isBlocking ? 2.0 : 1.2,
            dash: isBlocking ? [] : [6, 4]
        )
        ctx.stroke(curve, with: .color(color), style: style)

        let angle = atan2(end.y - cp2.y, end.x - cp2.x)
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
    let isBlocked: Bool
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title row
            HStack(spacing: 5) {
                Circle()
                    .fill(statusColor.opacity(isBlocked ? 0.4 : 1))
                    .frame(width: 5, height: 5)
                Text(snapshot.title.isEmpty ? "Untitled" : snapshot.title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(2)
                    .foregroundColor(isBlocked ? .secondary : .primary)
                Spacer(minLength: 0)
                priorityIndicator
            }

            if let name = snapshot.projectName {
                HStack(spacing: 4) {
                    if let color = snapshot.projectColor {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: color).opacity(isBlocked ? 0.4 : 0.7))
                            .frame(width: 6, height: 6)
                    }
                    Text(name)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                }
            }

            if !snapshot.tagNames.isEmpty {
                HStack(spacing: 3) {
                    ForEach(snapshot.tagNames.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 8))
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.secondary)
                            .cornerRadius(3)
                    }
                    if snapshot.tagNames.count > 2 {
                        Text("+\(snapshot.tagNames.count - 2)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }

            if let due = snapshot.dueDate {
                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.system(size: 8))
                    Text(formatDue(due))
                        .font(.system(size: 8))
                }
                .foregroundColor(due < Date() && !snapshot.isCompleted ? .red.opacity(0.8) : .secondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: 160, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(isBlocked ? 0.5 : 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(
                    isSelected ? Color.accentColor : Color.secondary.opacity(isBlocked ? 0.2 : 0.35),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(color: .black.opacity(isSelected ? 0.18 : 0.06), radius: isSelected ? 5 : 2, x: 0, y: 1)
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

    @ViewBuilder private var priorityIndicator: some View {
        switch snapshot.priorityValue {
        case .high:
            Text("!")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary.opacity(0.7))
        case .medium:
            Text("·")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary.opacity(0.5))
        case .low:
            EmptyView()
        }
    }
}
