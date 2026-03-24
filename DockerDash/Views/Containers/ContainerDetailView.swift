import SwiftUI

struct ContainerDetailView: View {
    let container: DockerContainer
    let service: ContainerService
    @State private var logs = ""
    @State private var isLoadingLogs = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ContainerStatusBadge(state: container.state)
                    Text(container.displayName).font(.title3.bold())
                    Text(container.shortId).font(.caption.monospaced()).foregroundStyle(.tertiary)
                    Spacer()
                    actionButtons
                }
                HStack(spacing: 12) {
                    Text(container.image).font(.caption).foregroundStyle(.secondary)
                    Text(container.status).font(.caption).foregroundStyle(.tertiary)
                    if let ports = container.ports?.filter({ $0.publicPort != nil }) {
                        ForEach(ports, id: \.privatePort) { port in
                            Text(port.displayString).font(.caption.monospaced()).foregroundStyle(.blue)
                        }
                    }
                }
            }
            .padding()

            Divider()

            Picker("", selection: $selectedTab) {
                Text("Logs").tag(0)
                Text("Stats").tag(1)
                Text("Info").tag(2)
                Text("Labels").tag(3)
                Text("Mounts").tag(4)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 6)

            switch selectedTab {
            case 0:
                if container.isRunning {
                    LogSearchView(containerId: container.id, containerName: container.displayName)
                } else {
                    logsView
                }
            case 1:
                if container.isRunning {
                    ResourceMonitorView(containerId: container.id, containerName: container.displayName)
                } else {
                    EmptyStateView(title: "Container Stopped", subtitle: "Start the container to see live stats.", systemImage: "chart.line.uptrend.xyaxis")
                }
            case 2: infoView
            case 3: envView
            case 4: mountsView
            default: EmptyView()
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 6) {
            if container.isStopped {
                Button("Start") { Task { try? await service.startContainer(container.id) } }
                    .buttonStyle(.borderedProminent).tint(.green).controlSize(.small)
            }
            if container.isRunning {
                Button("Stop") { Task { try? await service.stopContainer(container.id) } }
                    .buttonStyle(.bordered).controlSize(.small)
            }
            Button("Restart") { Task { try? await service.restartContainer(container.id) } }
                .buttonStyle(.bordered).controlSize(.small)
            Button("Remove") { Task { try? await service.removeContainer(container.id, force: true) } }
                .buttonStyle(.bordered).controlSize(.small).foregroundStyle(.red)
        }
    }

    private var logsView: some View {
        ScrollView {
            if isLoadingLogs {
                ProgressView().padding()
            } else {
                Text(logs.isEmpty ? "No logs available" : logs)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await fetchLogs() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { Task { await fetchLogs() } }) {
                    Image(systemName: "arrow.clockwise")
                }.help("Refresh logs")
            }
        }
    }

    private var infoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                GroupBox("Container") {
                    VStack(alignment: .leading, spacing: 6) {
                        infoRow("ID", container.id)
                        infoRow("Name", container.displayName)
                        infoRow("Image", container.image)
                        infoRow("Command", container.command)
                        infoRow("Created", container.createdDate.formatted())
                        infoRow("State", container.state)
                        infoRow("Status", container.status)
                        if let project = container.composeProject {
                            infoRow("Compose Project", project)
                        }
                        if let svc = container.composeService {
                            infoRow("Compose Service", svc)
                        }
                    }.padding(.vertical, 4)
                }
            }.padding()
        }
    }

    private var envView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                if let labels = container.labels {
                    ForEach(labels.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack(alignment: .top) {
                            Text(key).font(.caption.monospaced().bold()).frame(width: 250, alignment: .leading)
                            Text(value).font(.caption.monospaced()).foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                        Divider()
                    }
                } else {
                    Text("No labels").font(.caption).foregroundStyle(.secondary)
                }
            }.padding()
        }
    }

    private var mountsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if let mounts = container.mounts, !mounts.isEmpty {
                    ForEach(Array(mounts.enumerated()), id: \.offset) { _, mount in
                        GroupBox {
                            VStack(alignment: .leading, spacing: 4) {
                                if let src = mount.source { infoRow("Source", src) }
                                if let dst = mount.destination { infoRow("Destination", dst) }
                                if let type = mount.type { infoRow("Type", type) }
                                infoRow("Read/Write", mount.rw == true ? "Yes" : "No")
                            }.padding(.vertical, 2)
                        }
                    }
                } else {
                    Text("No mounts").font(.caption).foregroundStyle(.secondary)
                }
            }.padding()
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 120, alignment: .leading)
            Text(value).font(.caption.bold()).textSelection(.enabled)
            Spacer()
        }
    }

    private func fetchLogs() async {
        isLoadingLogs = true
        do {
            logs = try await service.getContainerLogs(container.id, tail: 500)
        } catch {
            logs = "Error: \(error.localizedDescription)"
        }
        isLoadingLogs = false
    }
}
