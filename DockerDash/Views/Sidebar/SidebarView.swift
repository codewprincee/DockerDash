import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @State private var containerService = ContainerService()

    var body: some View {
        @Bindable var state = appState
        List(selection: $state.selectedSection) {
            Section("Docker") {
                ForEach(AppState.SidebarSection.allCases.filter { $0 != .settings }) { section in
                    Label {
                        HStack {
                            Text(section.title)
                            Spacer()
                            if section == .containers {
                                Text("\(containerService.runningCount)")
                                    .font(.caption2.bold()).foregroundStyle(.white)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(.green, in: Capsule())
                            }
                        }
                    } icon: {
                        Image(systemName: section.icon)
                    }
                    .tag(section)
                }
            }
            Section {
                Label("Settings", systemImage: "gear")
                    .tag(AppState.SidebarSection.settings)
            }
        }
        .listStyle(.sidebar)
        .task { await containerService.fetchContainers() }
    }
}
