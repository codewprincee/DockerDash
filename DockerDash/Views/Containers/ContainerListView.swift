import SwiftUI

struct ContainerListView: View {
    @State private var containerService = ContainerService()
    @State private var filter: ContainerFilter = .running
    @State private var searchText = ""
    @State private var selectedContainer: DockerContainer?
    @State private var polling = PollingManager()

    enum ContainerFilter: String, CaseIterable {
        case all = "All"
        case running = "Running"
        case stopped = "Stopped"
    }

    private var filtered: [DockerContainer] {
        var result = containerService.containers
        switch filter {
        case .running: result = result.filter(\.isRunning)
        case .stopped: result = result.filter(\.isStopped)
        case .all: break
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.image.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack {
                    Picker("Filter", selection: $filter) {
                        ForEach(ContainerFilter.allCases, id: \.self) { f in Text(f.rawValue).tag(f) }
                    }
                    .pickerStyle(.segmented)
                    TextField("Search...", text: $searchText).textFieldStyle(.roundedBorder).frame(maxWidth: 150)
                }
                .padding(8)

                if containerService.isLoading && containerService.containers.isEmpty {
                    LoadingStateView()
                } else if filtered.isEmpty {
                    EmptyStateView(title: "No Containers", subtitle: "No containers match your filter.", systemImage: "shippingbox")
                } else {
                    List(filtered, selection: $selectedContainer) { container in
                        ContainerRowView(container: container, onAction: { action in
                            Task { await performAction(action, on: container) }
                        })
                        .tag(container)
                    }
                    .listStyle(.inset)
                }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)
        } detail: {
            if let container = selectedContainer {
                ContainerDetailView(container: container, service: containerService)
            } else {
                EmptyStateView(title: "Select a Container", subtitle: "Choose a container to view details.", systemImage: "shippingbox")
            }
        }
        .navigationTitle("Containers (\(containerService.runningCount) running)")
        .task {
            await containerService.fetchContainers()
            polling.startPolling(id: "containers", interval: 3) { await containerService.fetchContainers() }
        }
        .onDisappear { polling.stopAll() }
    }

    private func performAction(_ action: ContainerAction, on container: DockerContainer) async {
        do {
            switch action {
            case .start: try await containerService.startContainer(container.id)
            case .stop: try await containerService.stopContainer(container.id)
            case .restart: try await containerService.restartContainer(container.id)
            case .remove: try await containerService.removeContainer(container.id, force: true)
            }
        } catch {}
    }
}

enum ContainerAction { case start, stop, restart, remove }

struct ContainerRowView: View {
    let container: DockerContainer
    var onAction: (ContainerAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                ContainerStatusBadge(state: container.state)
                Text(container.displayName).font(.body.weight(.medium)).lineLimit(1)
                Spacer()
            }
            HStack(spacing: 8) {
                Text(container.image).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                if let ports = container.ports, let pub = ports.first(where: { $0.publicPort != nil }) {
                    Text(":\(pub.publicPort!)").font(.caption.monospaced()).foregroundStyle(.blue)
                }
                Spacer()
                Text(container.status).font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            if container.isStopped { Button("Start") { onAction(.start) } }
            if container.isRunning { Button("Stop") { onAction(.stop) } }
            Button("Restart") { onAction(.restart) }
            Divider()
            Button("Remove", role: .destructive) { onAction(.remove) }
        }
    }
}
