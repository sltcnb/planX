import SwiftUI

struct ExportImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var exportFormat: ExportFormat = .json
    @State private var importFormat: ImportFormat = .json
    @State private var showingFilePicker = false
    @State private var importedFileURL: URL?
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Export / Import")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
            }
            
            Divider()
            
            TabView {
                exportTab
                    .tabItem {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                
                importTab
                    .tabItem {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
            }
        }
        .padding(20)
        .frame(width: 500, height: 400)
    }
    
    private var exportTab: some View {
        VStack(spacing: 20) {
            Picker("Format", selection: $exportFormat) {
                Text("JSON").tag(ExportFormat.json)
                Text("CSV").tag(ExportFormat.csv)
            }
            .pickerStyle(.segmented)
            
            Text("Export all tasks to \(exportFormat == .json ? "JSON" : "CSV") format")
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Export") {
                    exportTasks()
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding()
    }
    
    private var importTab: some View {
        VStack(spacing: 20) {
            Picker("Format", selection: $importFormat) {
                Text("JSON").tag(ImportFormat.json)
                Text("CSV").tag(ImportFormat.csv)
            }
            .pickerStyle(.segmented)
            
            Text("Import tasks from \(importFormat == .json ? "JSON" : "CSV") file")
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                if let url = importedFileURL {
                    Text(url.lastPathComponent)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button("Choose File") {
                    showingFilePicker = true
                }
                
                Button("Import") {
                    importTasks()
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(importedFileURL == nil)
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: importFormat == .json ? [.json] : [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                importedFileURL = urls.first
            case .failure(let error):
                print("Import error: \(error)")
            }
        }
    }
    
    private func exportTasks() {
        guard let data = ExportImportService.shared.exportAllTasks(format: exportFormat, context: modelContext) else {
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = exportFormat == .json ? [.json] : [.commaSeparatedText]
        savePanel.nameFieldStringValue = "planner-export.\(exportFormat == .json ? "json" : "csv")"
        
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            
            do {
                try data.write(to: url)
            } catch {
                print("Export error: \(error)")
            }
        }
    }
    
    private func importTasks() {
        guard let url = importedFileURL,
              let data = try? Data(contentsOf: url) else {
            return
        }
        
        let importedTasks = ExportImportService.shared.importTasks(
            from: data,
            format: importFormat,
            context: modelContext
        )
        
        print("Imported \(importedTasks.count) tasks")
    }
}
