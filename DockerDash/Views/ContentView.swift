import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var systemService = SystemService()

    var body: some View {
        Group {
            if appState.isDockerConnected {
                MainView()
            } else {
                DockerNotRunningView {
                    Task {
                        let ok = await systemService.checkConnection()
                        appState.isDockerConnected = ok
                    }
                }
            }
        }
        .task {
            let ok = await systemService.checkConnection()
            appState.isDockerConnected = ok
        }
    }
}

struct MainView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 280)
        } detail: {
            switch appState.selectedSection {
            case .dashboard:  DashboardView()
            case .containers: ContainerListView()
            case .images:     ImageListView()
            case .volumes:    VolumeListView()
            case .networks:   NetworkListView()
            case .ports:      PortMapView()
            case .compose:    ComposeListView()
            case .cleanup:    CleanupWizardInlineView()
            case .settings:   SettingsView()
            }
        }
        .frame(minWidth: 1060, minHeight: 720)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { appState.showQuickRun = true }) {
                    Label("Quick Run", systemImage: "play.circle")
                }
                .help("Run a container")

                Button(action: { appState.showCommandPalette = true }) {
                    Label("Command Palette", systemImage: "command")
                }
                .help("Command Palette")
                .keyboardShortcut("k", modifiers: .command)
            }
        }
        .sheet(isPresented: $state.showCommandPalette) {
            CommandPaletteView()
        }
        .sheet(isPresented: $state.showQuickRun) {
            QuickRunView()
        }
    }
}

struct CleanupWizardInlineView: View {
    @State private var showWizard = false

    var body: some View {
        VStack(spacing: DDTokens.space20) {
            DDEmptyState(
                icon: "trash.circle",
                title: "Docker Cleanup",
                subtitle: "Remove unused containers, images, volumes, and networks to free disk space.",
                actionTitle: "Start Cleanup Wizard",
                action: { showWizard = true }
            )
        }
        .sheet(isPresented: $showWizard) { CleanupWizardView() }
    }
}
