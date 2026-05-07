import SwiftUI

struct MarkdownNotesView: View {
    @Binding var text: String
    @State private var isPreview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .foregroundColor(.secondary)
                    
                    Text("Notes")
                        .font(.headline)
                }
                
                Spacer()
                
                Toggle("Preview", isOn: $isPreview)
                    .toggleStyle(.switch)
            }
            
            if isPreview {
                // Markdown preview using Text with markdown formatting
                ScrollView {
                    Text(text)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(minHeight: 200)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            } else {
                // Edit mode
                TextEditor(text: $text)
                    .font(.body)
                    .padding(8)
                    .frame(minHeight: 200)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
            }
            
            // Markdown formatting toolbar
            if !isPreview {
                Divider()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(markdownButtons, id: \.symbol) { button in
                            Button(action: { insertMarkdown(button.text) }) {
                                Image(systemName: button.symbol)
                                    .help(button.label)
                                    .padding(6)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    private var markdownButtons: [(symbol: String, text: String, label: String)] {
        [
            ("bold", "**text**", "Bold"),
            ("italic", "*text*", "Italic"),
            ("list.bullet", "- item", "Bullet List"),
            ("list.number", "1. item", "Numbered List"),
            ("quote.open", "> quote", "Quote"),
            ("code", "`code`", "Inline Code"),
            ("link", "[text](url)", "Link"),
            ("divider", "\n---\n", "Divider")
        ]
    }
    
    private func insertMarkdown(_ markdown: String) {
        // Insert at cursor position or at end
        text += markdown
    }
}

#Preview {
    MarkdownNotesView(text: .constant("# Hello\n\nThis is **bold** and *italic*\n\n- List item 1\n- List item 2"))
        .padding()
        .frame(width: 400)
}
