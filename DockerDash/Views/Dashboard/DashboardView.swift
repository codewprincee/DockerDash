import SwiftUI

struct DashboardView: View {
    @State private var systemService = SystemService()
    @State private var containerService = ContainerService()
    @State private var imageService = ImageService()
    @State private var volumeService = VolumeService()
    @State private var polling = PollingManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // System info
                if let info = systemService.systemInfo, let ver = systemService.version {
                    GroupBox("Docker Engine") {
                        HStack(spacing: 40) {
                            infoItem("Version", value: ver.version ?? "?")
                            infoItem("OS", value: info.operatingSystem ?? "?")
                            infoItem("CPUs", value: "\(info.ncpu ?? 0)")
                            infoItem("Memory", value: info.memTotalFormatted)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Stats cards
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12) {
                    statCard("Containers", icon: "shippingbox", value: "\(containerService.containers.count)",
                             subtitle: "\(containerService.runningCount) running", color: .blue)
                    statCard("Images", icon: "photo.stack", value: "\(imageService.images.count)",
                             subtitle: "Total", color: .purple)
                    statCard("Volumes", icon: "externaldrive", value: "\(volumeService.volumes.count)",
                             subtitle: "Total", color: .orange)
                }

                // Running containers
                if !containerService.containers.filter(\.isRunning).isEmpty {
                    GroupBox("Running Containers") {
                        VStack(spacing: 0) {
                            ForEach(containerService.containers.filter(\.isRunning)) { container in
                                HStack {
                                    ContainerStatusBadge(state: container.state)
                                    Text(container.displayName).font(.body.weight(.medium))
                                    Text(container.image).font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    if let ports = container.ports?.compactMap(\.publicPort).first {
                                        Text(":\(ports)").font(.caption.monospaced()).foregroundStyle(.blue)
                                    }
                                    Text(container.status).font(.caption).foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 6)
                                if container.id != containerService.containers.filter(\.isRunning).last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .task {
            await systemService.fetchInfo()
            await containerService.fetchContainers()
            await imageService.fetchImages()
            await volumeService.fetchVolumes()
            polling.startPolling(id: "dashboard", interval: 5) {
                await containerService.fetchContainers()
            }
        }
        .onDisappear { polling.stopAll() }
    }

    private func infoItem(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.body.bold())
        }
    }

    private func statCard(_ title: String, icon: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).font(.title2).foregroundStyle(color)
                Spacer()
            }
            Text(value).font(.title.bold())
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(.background))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
    }
}
