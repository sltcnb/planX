import SwiftUI

struct AttachmentSectionView: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "paperclip")
                        .foregroundColor(.secondary)
                    
                    Text("Attachments")
                        .font(.headline)
                    
                    Text("\(viewModel.task?.attachments.count ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                Button(action: { showingFilePicker = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Add Attachment")
            }
            .padding(16)
            
            if viewModel.task?.attachments.isEmpty ?? true {
                Text("Add files, links, or images")
                    .foregroundColor(.secondary)
                    .padding(16)
            } else {
                ForEach(viewModel.task?.attachments ?? [], id: \.id) { attachment in
                    HStack(spacing: 12) {
                        Image(systemName: "doc")
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(attachment.name)
                                .font(.body)
                                .lineLimit(1)
                            
                            Text(formatSize(attachment.fileSize))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            AttachmentService.shared.deleteAttachment(attachment, context: modelContext)
                            viewModel.refresh()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(Color.secondary.opacity(0.05))
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    _ = AttachmentService.shared.addFileAttachment(
                        to: viewModel.task!,
                        fileURL: url,
                        context: modelContext
                    )
                }
                viewModel.refresh()
            case .failure(let error):
                print("File import error: \(error)")
            }
        }
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

#Preview {
    AttachmentSectionView(viewModel: TaskDetailViewModel())
}
