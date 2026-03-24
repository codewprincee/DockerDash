import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var systemService = SystemService()
    @State private var containerService = ContainerService()
    @State private var imageService = ImageService()
    @State private var volumeService = VolumeService()
    @State private var networkService = NetworkService()
    @State private var polling = PollingManager()

    private var runningContainers: [DockerContainer] {
        containerService.containers.filter(\.isRunning)
    }

    private var stoppedContainers: [DockerContainer] {
        containerService.containers.filter(\.isStopped)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DDTokens.space24) {

                // MARK: - Header
                dashboardHeader

                // MARK: - Stat Cards Grid
                statCardsGrid

                // MARK: - System Resources
                if let info = systemService.systemInfo {
                    systemResourcesCard(info)
                }

                // MARK: - Running Containers
                if !runningContainers.isEmpty {
                    runningContainersCard
                }

                // MARK: - Stopped Containers
                if !stoppedContainers.isEmpty {
                    stoppedContainersCard
                }
            }
            .padding(DDTokens.space24)
        }
        .background(DDColors.groupedBackground.opacity(0.3))
        .navigationTitle("Dashboard")
        .task {
            async let sysTask: () = systemService.fetchInfo()
            async let conTask: () = containerService.fetchContainers()
            async let imgTask: () = imageService.fetchImages()
            async let volTask: () = volumeService.fetchVolumes()
            async let netTask: () = networkService.fetchNetworks()
            _ = await (sysTask, conTask, imgTask, volTask, netTask)

            polling.startPolling(id: "dash-containers", interval: 5) {
                await containerService.fetchContainers()
            }
        }
        .onDisappear { polling.stopAll() }
    }

    // MARK: - Dashboard Header

    private var dashboardHeader: some View {
        DDGlassCard {
            HStack(spacing: DDTokens.space16) {
                DockerLogo(size: 44)

                VStack(alignment: .leading, spacing: DDTokens.space4) {
                    Text("Docker Dashboard")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(DDColors.textPrimary)

                    HStack(spacing: DDTokens.space12) {
                        if let ver = systemService.version {
                            inlineChip(
                                icon: "shippingbox",
                                text: "Docker \(ver.version ?? "?")"
                            )
                            inlineChip(
                                icon: "cpu",
                                text: ver.arch ?? "?"
                            )
                        }
                        if let os = systemService.systemInfo?.operatingSystem {
                            inlineChip(
                                icon: "desktopcomputer",
                                text: os
                            )
                        }
                    }
                }

                Spacer()

                // Quick summary
                HStack(spacing: DDTokens.space20) {
                    summaryNumber(
                        value: containerService.runningCount,
                        label: "Running",
                        color: DDColors.success
                    )
                    summaryNumber(
                        value: containerService.stoppedCount,
                        label: "Stopped",
                        color: DDColors.textTertiary
                    )
                }
            }
        }
    }

    private func inlineChip(icon: String, text: String) -> some View {
        HStack(spacing: DDTokens.space4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DDColors.textTertiary)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DDColors.textSecondary)
        }
        .padding(.horizontal, DDTokens.space8)
        .padding(.vertical, DDTokens.space4)
        .background(
            Capsule().fill(Color.primary.opacity(0.04))
        )
    }

    private func summaryNumber(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: DDTokens.space2) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DDColors.textTertiary)
        }
    }

    // MARK: - Stat Cards

    private var statCardsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 170, maximum: 240), spacing: DDTokens.space12)],
            spacing: DDTokens.space12
        ) {
            DDStatCard(
                title: "Containers",
                value: "\(containerService.containers.count)",
                icon: "shippingbox.fill",
                color: DDColors.brandBlue
            )
            DDStatCard(
                title: "Running",
                value: "\(containerService.runningCount)",
                icon: "play.circle.fill",
                color: DDColors.success
            )
            DDStatCard(
                title: "Stopped",
                value: "\(containerService.stoppedCount)",
                icon: "stop.circle.fill",
                color: DDColors.danger
            )
            DDStatCard(
                title: "Images",
                value: "\(imageService.images.count)",
                icon: "photo.stack.fill",
                color: .purple
            )
            DDStatCard(
                title: "Volumes",
                value: "\(volumeService.volumes.count)",
                icon: "externaldrive.fill",
                color: .orange
            )
            DDStatCard(
                title: "Networks",
                value: "\(networkService.networks.count)",
                icon: "network",
                color: .cyan
            )
        }
    }

    // MARK: - System Resources Card

    private func systemResourcesCard(_ info: DockerSystemInfo) -> some View {
        DDCard {
            VStack(alignment: .leading, spacing: DDTokens.space16) {
                DDSectionHeader("System Resources")

                HStack(spacing: 0) {
                    resourceItem(
                        icon: "cpu",
                        value: "\(info.ncpu ?? 0)",
                        label: "CPU Cores",
                        color: DDColors.brandBlue
                    )
                    Divider().frame(height: 40)
                    resourceItem(
                        icon: "memorychip",
                        value: info.memTotalFormatted,
                        label: "Memory",
                        color: .purple
                    )
                    if let ver = systemService.version {
                        Divider().frame(height: 40)
                        resourceItem(
                            icon: "doc.text",
                            value: "v\(ver.apiVersion ?? "?")",
                            label: "API Version",
                            color: .orange
                        )
                        Divider().frame(height: 40)
                        resourceItem(
                            icon: "desktopcomputer",
                            value: ver.arch ?? "?",
                            label: "Architecture",
                            color: .cyan
                        )
                    }
                }
            }
        }
    }

    private func resourceItem(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: DDTokens.space10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: DDTokens.radiusSm, style: .continuous))

            VStack(alignment: .leading, spacing: DDTokens.space2) {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(DDColors.textPrimary)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DDColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DDTokens.space4)
    }

    // MARK: - Running Containers

    private var runningContainersCard: some View {
        DDCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                DDSectionHeader("Running Containers", count: runningContainers.count)
                    .padding(.horizontal, DDTokens.space16)
                    .padding(.top, DDTokens.space16)
                    .padding(.bottom, DDTokens.space12)

                Divider().opacity(0.5)

                ForEach(Array(runningContainers.enumerated()), id: \.element.id) { index, container in
                    dashboardContainerRow(container, showDivider: index < runningContainers.count - 1)
                }
            }
        }
    }

    // MARK: - Stopped Containers

    private var stoppedContainersCard: some View {
        DDCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                DDSectionHeader("Recently Stopped", count: stoppedContainers.count)
                    .padding(.horizontal, DDTokens.space16)
                    .padding(.top, DDTokens.space16)
                    .padding(.bottom, DDTokens.space12)

                Divider().opacity(0.5)

                ForEach(Array(stoppedContainers.prefix(5).enumerated()), id: \.element.id) { index, container in
                    stoppedContainerRow(container, showDivider: index < min(stoppedContainers.count, 5) - 1)
                }
            }
        }
    }

    private func dashboardContainerRow(_ container: DockerContainer, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: DDTokens.space12) {
                DDStatusPill(state: container.state, compact: true)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: DDTokens.space2) {
                    Text(container.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DDColors.textPrimary)
                        .lineLimit(1)
                    Text(container.image)
                        .font(.system(size: 11))
                        .foregroundStyle(DDColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                // Port pills
                if let ports = container.ports?.compactMap(\.publicPort), !ports.isEmpty {
                    HStack(spacing: DDTokens.space4) {
                        ForEach(ports.prefix(2), id: \.self) { port in
                            DDPortPill(port: port)
                        }
                    }
                }

                Text(container.status)
                    .font(.system(size: 11))
                    .foregroundStyle(DDColors.textTertiary)
                    .frame(minWidth: 60, alignment: .trailing)

                // Quick actions
                HStack(spacing: DDTokens.space4) {
                    DDIconButton(icon: "stop.fill", color: DDColors.danger, help: "Stop") {
                        Task { try? await containerService.stopContainer(container.id) }
                    }
                    DDIconButton(icon: "arrow.clockwise", color: DDColors.brandBlue, help: "Restart") {
                        Task { try? await containerService.restartContainer(container.id) }
                    }
                }
            }
            .padding(.horizontal, DDTokens.space16)
            .padding(.vertical, DDTokens.space10)

            if showDivider {
                Divider()
                    .padding(.leading, 54)
                    .opacity(0.4)
            }
        }
    }

    private func stoppedContainerRow(_ container: DockerContainer, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: DDTokens.space12) {
                DDStatusPill(state: container.state, compact: true)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: DDTokens.space2) {
                    Text(container.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DDColors.textPrimary)
                        .lineLimit(1)
                    Text(container.image)
                        .font(.system(size: 11))
                        .foregroundStyle(DDColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(container.status)
                    .font(.system(size: 11))
                    .foregroundStyle(DDColors.textTertiary)

                Button {
                    Task { try? await containerService.startContainer(container.id) }
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(DDColors.success)
                .controlSize(.small)
            }
            .padding(.horizontal, DDTokens.space16)
            .padding(.vertical, DDTokens.space10)

            if showDivider {
                Divider()
                    .padding(.leading, 54)
                    .opacity(0.4)
            }
        }
    }
}
