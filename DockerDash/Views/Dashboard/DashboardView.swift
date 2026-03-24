import SwiftUI

struct DashboardView: View {
    @State private var systemService = SystemService()
    @State private var containerService = ContainerService()
    @State private var imageService = ImageService()
    @State private var volumeService = VolumeService()
    @State private var networkService = NetworkService()
    @State private var polling = PollingManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    DockerLogo(size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Docker Dashboard").font(.title.bold())
                        if let ver = systemService.version {
                            Text("Docker \(ver.version ?? "?") · \(systemService.systemInfo?.operatingSystem ?? "")")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                    DDStatCard(title: "Containers", value: "\(containerService.containers.count)", icon: "shippingbox.fill", color: DDColors.brand)
                    DDStatCard(title: "Running", value: "\(containerService.runningCount)", icon: "play.circle.fill", color: DDColors.success)
                    DDStatCard(title: "Stopped", value: "\(containerService.stoppedCount)", icon: "stop.circle.fill", color: DDColors.stopped)
                    DDStatCard(title: "Images", value: "\(imageService.images.count)", icon: "photo.stack.fill", color: .purple)
                    DDStatCard(title: "Volumes", value: "\(volumeService.volumes.count)", icon: "externaldrive.fill", color: .orange)
                    DDStatCard(title: "Networks", value: "\(networkService.networks.count)", icon: "network", color: .cyan)
                }

                if let info = systemService.systemInfo {
                    DDCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("System Resources").font(.headline)
                            HStack(spacing: 30) {
                                sysItem("CPUs", "\(info.ncpu ?? 0)", "cpu")
                                sysItem("Memory", info.memTotalFormatted, "memorychip")
                                if let ver = systemService.version {
                                    sysItem("API", ver.apiVersion ?? "?", "doc.text")
                                    sysItem("Arch", ver.arch ?? "?", "desktopcomputer")
                                }
                            }
                        }
                    }
                }

                if !containerService.containers.filter(\.isRunning).isEmpty {
                    DDCard {
                        VStack(alignment: .leading, spacing: 12) {
                            DDSectionHeader("Running Containers", count: containerService.runningCount)
                            ForEach(containerService.containers.filter(\.isRunning)) { c in
                                HStack(spacing: 12) {
                                    DDStatusPill(state: c.state)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(c.displayName).font(.body.weight(.medium))
                                        Text(c.image).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let p = c.ports?.compactMap({ $0.publicPort }).first {
                                        Text(":\(p)").font(.caption.monospaced()).foregroundStyle(DDColors.brand)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(DDColors.brand.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                                    }
                                    Text(c.status).font(.caption).foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Dashboard")
        .task {
            await systemService.fetchInfo()
            await containerService.fetchContainers()
            await imageService.fetchImages()
            await volumeService.fetchVolumes()
            await networkService.fetchNetworks()
            polling.startPolling(id: "dash", interval: 5) { await containerService.fetchContainers() }
        }
        .onDisappear { polling.stopAll() }
    }

    private func sysItem(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundStyle(.secondary).frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.body.bold())
                Text(title).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
