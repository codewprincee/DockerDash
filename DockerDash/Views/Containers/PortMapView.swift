import SwiftUI

struct PortMapView: View {
    @State private var containerService = ContainerService()
    @State private var portConflicts: [Int: [String]] = [:]

    private var allPorts: [(container: String, mapping: PortMapping)] {
        containerService.containers
            .filter(\.isRunning)
            .flatMap { container in
                (container.ports ?? [])
                    .filter { $0.publicPort != nil }
                    .map { (container: container.displayName, mapping: $0) }
            }
            .sorted { ($0.mapping.publicPort ?? 0) < ($1.mapping.publicPort ?? 0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "network").foregroundStyle(.cyan)
                Text("Port Mappings").font(.title3.bold())
                Spacer()
                Text("\(allPorts.count) ports mapped").font(.caption).foregroundStyle(.secondary)
                Button(action: { Task { await containerService.fetchContainers(); detectConflicts() } }) {
                    Image(systemName: "arrow.clockwise")
                }.buttonStyle(.plain)
            }
            .padding()

            Divider()

            if containerService.isLoading && containerService.containers.isEmpty {
                LoadingStateView()
            } else if allPorts.isEmpty {
                EmptyStateView(title: "No Port Mappings", subtitle: "No running containers have exposed ports.", systemImage: "network")
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Host Port").font(.caption.bold()).frame(width: 100, alignment: .leading)
                            Text("→").font(.caption).foregroundStyle(.secondary)
                            Text("Container Port").font(.caption.bold()).frame(width: 120, alignment: .leading)
                            Text("Protocol").font(.caption.bold()).frame(width: 60, alignment: .leading)
                            Text("Container").font(.caption.bold())
                            Spacer()
                            Text("Status").font(.caption.bold()).frame(width: 80)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(.quaternary.opacity(0.3))

                        ForEach(Array(allPorts.enumerated()), id: \.offset) { _, entry in
                            let conflict = portConflicts[entry.mapping.publicPort ?? 0]
                            let hasConflict = (conflict?.count ?? 0) > 1

                            HStack {
                                Text(":\(entry.mapping.publicPort ?? 0)")
                                    .font(.body.monospaced().bold())
                                    .foregroundStyle(hasConflict ? .red : .blue)
                                    .frame(width: 100, alignment: .leading)

                                Image(systemName: "arrow.right")
                                    .font(.caption).foregroundStyle(.tertiary)

                                Text(":\(entry.mapping.privatePort)")
                                    .font(.body.monospaced())
                                    .frame(width: 120, alignment: .leading)

                                Text(entry.mapping.type)
                                    .font(.caption.monospaced())
                                    .padding(.horizontal, 4).padding(.vertical, 1)
                                    .background(.quaternary, in: Capsule())
                                    .frame(width: 60, alignment: .leading)

                                Text(entry.container)
                                    .font(.body)
                                    .lineLimit(1)

                                Spacer()

                                if hasConflict {
                                    HStack(spacing: 3) {
                                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                                        Text("Conflict").font(.caption2).foregroundStyle(.red)
                                    }
                                    .frame(width: 80)
                                } else {
                                    HStack(spacing: 3) {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                        Text("OK").font(.caption2).foregroundStyle(.green)
                                    }
                                    .frame(width: 80)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(hasConflict ? Color.red.opacity(0.05) : Color.clear)

                            Divider().padding(.leading)
                        }

                        // Conflict summary
                        if !portConflicts.filter({ $0.value.count > 1 }).isEmpty {
                            GroupBox {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Port Conflicts Detected", systemImage: "exclamationmark.triangle.fill")
                                        .font(.body.bold()).foregroundStyle(.red)
                                    ForEach(portConflicts.filter({ $0.value.count > 1 }).sorted(by: { $0.key < $1.key }), id: \.key) { port, containers in
                                        Text("Port \(port) used by: \(containers.joined(separator: ", "))")
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .task {
            await containerService.fetchContainers()
            detectConflicts()
        }
    }

    private func detectConflicts() {
        var map: [Int: [String]] = [:]
        for entry in allPorts {
            guard let pub = entry.mapping.publicPort else { continue }
            map[pub, default: []].append(entry.container)
        }
        portConflicts = map
    }
}
