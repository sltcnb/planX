import SwiftUI
import SwiftData

struct TaskGraphView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var nodePositions: [UUID: CGPoint] = [:]
    @State private var draggingID: UUID?
    @State private var dragOffset: CGPoint = .zero
    @State private var panOffset: CGSize = .zero
    @State private var panStart: CGSize = .zero
    @State private var scale: CGFloat = 1.0

    private var tasks: [TaskItem] { viewModel.getFilteredTasks() }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(NSColor.underPageBackgroundColor)

                Canvas { ctx, size in
                    for task in tasks {
                        guard let fromPos = resolvedPos(task.id, size: size) else { continue }
                        for dep in task.dependencies {
                            guard let targetTask = dep.successor,
                                  targetTask.id != task.id,
                                  let toPos = resolvedPos(targetTask.id, size: size) else { continue }
                            drawArrow(ctx: ctx, from: applyTransform(fromPos), to: applyTransform(toPos),
                                      color: depColor(dep.relationshipType))
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)

                ForEach(tasks, id: \.id) { task in
                    if let pos = resolvedPos(task.id, size: geo.size) {
                        TaskNodeView(task: task)
                            .position(applyTransform(pos))
                            .gesture(
                                DragGesture()
                                    .onChanged { val in
                                        var p = pos
                                        p.x += val.translation.width / scale
                                        p.y += val.translation.height / scale
                                        nodePositions[task.id] = p
                                    }
                            )
                    }
                }

                legendView
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .gesture(
                MagnificationGesture()
                    .onChanged { val in scale = max(0.3, min(2.5, val)) }
            )
            .gesture(
                DragGesture()
                    .onChanged { val in
                        panOffset = CGSize(
                            width: panStart.width + val.translation.width,
                            height: panStart.height + val.translation.height
                        )
                    }
                    .onEnded { _ in panStart = panOffset }
            )
            .onAppear { layoutNodes(in: geo.size) }
            .onChange(of: tasks.count) { layoutNodes(in: geo.size) }
        }
    }

    private func applyTransform(_ p: CGPoint) -> CGPoint {
        CGPoint(
            x: p.x * scale + panOffset.width,
            y: p.y * scale + panOffset.height
        )
    }

    private func resolvedPos(_ id: UUID, size: CGSize) -> CGPoint? {
        nodePositions[id]
    }

    private func layoutNodes(in size: CGSize) {
        var depthMap: [UUID: Int] = [:]
        for task in tasks {
            if depthMap[task.id] == nil {
                var visited = Set<UUID>()
                depthMap[task.id] = computeDepth(task, visited: &visited)
            }
        }
        var byDepth: [Int: [TaskItem]] = [:]
        for task in tasks {
            let d = depthMap[task.id] ?? 0
            byDepth[d, default: []].append(task)
        }
        let nodeW: CGFloat = 160
        let nodeH: CGFloat = 64
        let hGap: CGFloat = 40
        let vGap: CGFloat = 40
        let maxDepth = byDepth.keys.max() ?? 0
        for (depth, tasksAtDepth) in byDepth {
            let col = depth
            let rows = tasksAtDepth.count
            let totalH = CGFloat(rows) * nodeH + CGFloat(rows - 1) * vGap
            let startY = (size.height - totalH) / 2
            let x = CGFloat(col) * (nodeW + hGap) + nodeW / 2 + 40
            for (row, task) in tasksAtDepth.enumerated() {
                if nodePositions[task.id] == nil {
                    let y = startY + CGFloat(row) * (nodeH + vGap) + nodeH / 2
                    nodePositions[task.id] = CGPoint(x: x, y: y)
                }
            }
        }
        _ = maxDepth
    }

    private func computeDepth(_ task: TaskItem, visited: inout Set<UUID>) -> Int {
        guard !visited.contains(task.id) else { return 0 }
        visited.insert(task.id)
        let blocked = task.blockedByTasks
        if blocked.isEmpty { return 0 }
        var maxDepth = 0
        for t in blocked {
            let d = computeDepth(t, visited: &visited)
            if d > maxDepth { maxDepth = d }
        }
        return 1 + maxDepth
    }

    private func depColor(_ type: String) -> Color {
        switch type {
        case "blocks": return .red.opacity(0.7)
        case "related": return .blue.opacity(0.7)
        default: return .secondary.opacity(0.5)
        }
    }

    private func drawArrow(ctx: GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let len = sqrt(dx * dx + dy * dy)
        guard len > 1 else { return }
        let ux = dx / len, uy = dy / len
        let arrowLen: CGFloat = 10
        let nodeR: CGFloat = 32
        let startX = from.x + ux * nodeR
        let startY = from.y + uy * nodeR
        let endX = to.x - ux * nodeR
        let endY = to.y - uy * nodeR

        var line = Path()
        line.move(to: CGPoint(x: startX, y: startY))
        line.addLine(to: CGPoint(x: endX, y: endY))
        ctx.stroke(line, with: .color(color), lineWidth: 1.5)

        let angle = atan2(uy, ux)
        let a1 = angle + .pi * 5 / 6
        let a2 = angle - .pi * 5 / 6
        var head = Path()
        head.move(to: CGPoint(x: endX, y: endY))
        head.addLine(to: CGPoint(x: endX + cos(a1) * arrowLen, y: endY + sin(a1) * arrowLen))
        head.addLine(to: CGPoint(x: endX + cos(a2) * arrowLen, y: endY + sin(a2) * arrowLen))
        head.closeSubpath()
        ctx.fill(head, with: .color(color))
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Blocks", systemImage: "arrow.right").foregroundColor(.red).font(.caption)
            Label("Related", systemImage: "arrow.left.arrow.right").foregroundColor(.blue).font(.caption)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct TaskNodeView: View {
    let task: TaskItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11))
                    .foregroundColor(task.isCompleted ? .green : .secondary)
                Text(task.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
            }
            HStack(spacing: 4) {
                if let project = task.project {
                    Circle().fill(Color(hex: project.color ?? "blue")).frame(width: 6, height: 6)
                    Text(project.name).font(.caption2).foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
                priorityDot
            }
        }
        .padding(10)
        .frame(width: 150)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(statusColor, lineWidth: 1.5))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
    }

    private var statusColor: Color {
        switch task.statusValue {
        case .notStarted: return .secondary.opacity(0.4)
        case .inProgress: return .blue
        case .waiting: return .orange
        case .done: return .green
        }
    }

    @ViewBuilder private var priorityDot: some View {
        switch task.priorityValue {
        case .high:
            Circle().fill(Color.red).frame(width: 7, height: 7)
        case .medium:
            Circle().fill(Color.orange).frame(width: 7, height: 7)
        case .low:
            EmptyView()
        }
    }
}
