import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
        }
        .frame(width: 450, height: 350)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("startOnToday") private var startOnToday = true
    
    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
            Toggle("Start on Today view", isOn: $startOnToday)
        }
        .padding(20)
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("appearance") private var appearance = "system"
    
    var body: some View {
        Form {
            Picker("Appearance", selection: $appearance) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
        }
        .padding(20)
    }
}

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            LabeledContent("New Task") {
                Text("⌘N")
                    .foregroundColor(.secondary)
            }
            
            LabeledContent("Search") {
                Text("⌘F")
                    .foregroundColor(.secondary)
            }
            
            LabeledContent("Mark Complete") {
                Text("⌘↩")
                    .foregroundColor(.secondary)
            }
            
            LabeledContent("Delete Task") {
                Text("⌘⌫")
                    .foregroundColor(.secondary)
            }
            
            LabeledContent("Toggle Sidebar") {
                Text("⌘⌥S")
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
    }
}
