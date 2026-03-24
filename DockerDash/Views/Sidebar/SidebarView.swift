import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @State private var containerService = ContainerService()

    var body: some View {
        @Bindable var state = appState
        List(selection: $state.selectedSection) {
            Section("Docker") {
                ForEach(AppState.SidebarSection.allCases.filter { $0 != .settings && $0 != .cleanup }) { section in
                    Label {
                        HStack {
                            Text(section.title)
                            Spacer()
                            if section == .containers && containerService.runningCount > 0 {
                                Text("\(containerService.runningCount)")
                                    .font(.caption2.bold()).foregroundStyle(.white)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(DDColors.success, in: Capsule())
                            }
                        }
                    } icon: {
                        Image(systemName: section.icon).foregroundStyle(iconColor(section))
                    }
                    .tag(section)
                }
            }

            Section("Tools") {
                Label("Cleanup", systemImage: "trash.circle")
                    .tag(AppState.SidebarSection.cleanup)
            }

            Section {
                Label("Settings", systemImage: "gear")
                    .tag(AppState.SidebarSection.settings)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top) {
            HStack(spacing: 8) {
                DockerLogo(size: 18)
                Text("DockerDash").font(.headline)
                Spacer()
                Circle().fill(DDColors.success).frame(width: 8, height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
        }
        .task { await containerService.fetchContainers() }
    }

    private func iconColor(_ section: AppState.SidebarSection) -> Color {
        switch section {
        case .dashboard: return DDColors.brand
        case .containers: return .blue
        case .images: return .purple
        case .volumes: return .orange
        case .networks: return .cyan
        case .ports: return .indigo
        case .compose: return .pink
        case .cleanup: return .red
        case .settings: return .gray
        }
    }
}
