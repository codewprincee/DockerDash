import SwiftUI

@main
struct DockerDashApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1300, height: 850)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("DockerDash") {
                Button("Command Palette") { appState.showCommandPalette.toggle() }
                    .keyboardShortcut("k", modifiers: .command)
                Divider()
                Button("Dashboard") { appState.selectedSection = .dashboard }.keyboardShortcut("1", modifiers: .command)
                Button("Containers") { appState.selectedSection = .containers }.keyboardShortcut("2", modifiers: .command)
                Button("Images") { appState.selectedSection = .images }.keyboardShortcut("3", modifiers: .command)
                Button("Volumes") { appState.selectedSection = .volumes }.keyboardShortcut("4", modifiers: .command)
                Button("Networks") { appState.selectedSection = .networks }.keyboardShortcut("5", modifiers: .command)
            }
        }
    }
}
