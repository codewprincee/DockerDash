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
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 260)
        } detail: {
            switch appState.selectedSection {
            case .dashboard: DashboardView()
            case .containers: ContainerListView()
            case .images: ImageListView()
            case .volumes: VolumeListView()
            case .networks: NetworkListView()
            case .compose: ComposeListView()
            case .settings: SettingsView()
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .sheet(isPresented: $state.showCommandPalette) {
            CommandPaletteView()
        }
    }
}
