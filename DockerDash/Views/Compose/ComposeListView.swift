import SwiftUI

struct ComposeListView: View {
    @State private var containerService = ContainerService()

    private var projects: [String: [DockerContainer]] {
        Dictionary(grouping: containerService.containers.filter { $0.composeProject != nil }) { $0.composeProject! }
    }

    var body: some View {
        Group {
            if containerService.isLoading && containerService.containers.isEmpty {
                LoadingStateView()
            } else if projects.isEmpty {
                EmptyStateView(title: "No Compose Projects", subtitle: "No Docker Compose projects detected.", systemImage: "rectangle.3.group")
            } else {
                List {
                    ForEach(projects.keys.sorted(), id: \.self) { project in
                        Section(project) {
                            ForEach(projects[project] ?? []) { container in
                                HStack {
                                    ContainerStatusBadge(state: container.state)
                                    Text(container.composeService ?? container.displayName).font(.body.weight(.medium))
                                    Text(container.image).font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Text(container.status).font(.caption2).foregroundStyle(.tertiary)
                                }
                                .contextMenu {
                                    if container.isStopped { Button("Start") { Task { try? await containerService.startContainer(container.id) } } }
                                    if container.isRunning { Button("Stop") { Task { try? await containerService.stopContainer(container.id) } } }
                                    Button("Restart") { Task { try? await containerService.restartContainer(container.id) } }
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Compose Projects")
        .task { await containerService.fetchContainers() }
    }
}
