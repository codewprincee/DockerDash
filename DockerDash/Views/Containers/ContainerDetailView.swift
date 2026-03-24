import SwiftUI

struct ContainerDetailView: View {
    let container: DockerContainer
    let service: ContainerService

    @Environment(\.colorScheme) private var colorScheme
    @State private var logs = ""
    @State private var isLoadingLogs = false
    @State private var selectedTab: DetailTab = .logs

    enum DetailTab: String, CaseIterable {
        case logs   = "Logs"
        case stats  = "Stats"
        case info   = "Info"
        case labels = "Labels"
        case mounts = "Mounts"

        var icon: String {
            switch self {
            case .logs:   return "text.alignleft"
            case .stats:  return "chart.xyaxis.line"
            case .info:   return "info.circle"
            case .labels: return "tag"
            case .mounts: return "externaldrive"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            detailHeader

            Divider().opacity(0.5)

            // MARK: - Tab Bar
            tabBar

            Divider().opacity(0.5)

            // MARK: - Tab Content
            tabContent
        }
        .background(DDColors.groupedBackground.opacity(0.3))
    }

    // MARK: - Detail Header

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: DDTokens.space12) {
            // Row 1: Name + Status + Actions
            HStack(spacing: DDTokens.space12) {
                // Container icon
                ZStack {
                    RoundedRectangle(cornerRadius: DDTokens.radiusMd, style: .continuous)
                        .fill(DDColors.stateColor(container.state).opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(DDColors.stateColor(container.state))
                }

                VStack(alignment: .leading, spacing: DDTokens.space4) {
                    HStack(spacing: DDTokens.space8) {
                        Text(container.displayName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(DDColors.textPrimary)

                        DDStatusPill(state: container.state)
                    }

                    HStack(spacing: DDTokens.space8) {
                        Text(container.shortId)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(DDColors.textTertiary)
                            .textSelection(.enabled)
                    }
                }

                Spacer()

                // Action buttons
                actionButtons
            }

            // Row 2: Metadata chips
            HStack(spacing: DDTokens.space8) {
                metadataChip(icon: "photo.stack", text: container.image)
                metadataChip(icon: "clock", text: container.status)

                if let ports = container.ports?.filter({ $0.publicPort != nil }), !ports.isEmpty {
                    ForEach(ports.prefix(4), id: \.privatePort) { port in
                        DDPortPill(port: port.publicPort!, type: port.type)
                    }
                }

                if let project = container.composeProject {
                    metadataChip(icon: "rectangle.3.group", text: project)
                }
            }
        }
        .padding(.horizontal, DDTokens.space20)
        .padding(.vertical, DDTokens.space16)
        .background(.bar)
    }

    private func metadataChip(icon: String, text: String) -> some View {
        HStack(spacing: DDTokens.space4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DDColors.textTertiary)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DDColors.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, DDTokens.space8)
        .padding(.vertical, DDTokens.space4)
        .background(
            Capsule().fill(Color.primary.opacity(0.04))
        )
        .overlay(
            Capsule().strokeBorder(DDColors.borderSubtle, lineWidth: 0.5)
        )
    }

    private var actionButtons: some View {
        HStack(spacing: DDTokens.space6) {
            if container.isStopped {
                Button {
                    Task { try? await service.startContainer(container.id) }
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(DDColors.success)
                .controlSize(.small)
            }

            if container.isRunning {
                DDIconButton(icon: "stop.fill", color: DDColors.danger, help: "Stop container") {
                    Task { try? await service.stopContainer(container.id) }
                }
            }

            DDIconButton(icon: "arrow.clockwise", color: DDColors.brandBlue, help: "Restart container") {
                Task { try? await service.restartContainer(container.id) }
            }

            DDIconButton(icon: "trash", color: DDColors.danger, help: "Remove container") {
                Task { try? await service.removeContainer(container.id, force: true) }
            }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: DDTokens.space2) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                DDTabButton(
                    title: tab.rawValue,
                    icon: tab.icon,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(DDTokens.springSnappy) {
                        selectedTab = tab
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, DDTokens.space16)
        .padding(.vertical, DDTokens.space6)
        .background(.bar)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .logs:
            logsTab
        case .stats:
            statsTab
        case .info:
            infoTab
        case .labels:
            labelsTab
        case .mounts:
            mountsTab
        }
    }

    // MARK: - Logs Tab

    private var logsTab: some View {
        Group {
            if container.isRunning {
                LogSearchView(containerId: container.id, containerName: container.displayName)
            } else {
                VStack(spacing: 0) {
                    if isLoadingLogs {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if logs.isEmpty {
                        DDEmptyState(
                            icon: "text.alignleft",
                            title: "No Logs Available",
                            subtitle: "This container has no log output to display.",
                            actionTitle: "Refresh",
                            action: { Task { await fetchLogs() } }
                        )
                    } else {
                        ScrollView {
                            Text(logs)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(DDColors.textPrimary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(DDTokens.space12)
                        }
                        .background(DDColors.codeBackground)
                    }
                }
                .task { await fetchLogs() }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task { await fetchLogs() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .help("Refresh logs")
                    }
                }
            }
        }
    }

    // MARK: - Stats Tab

    private var statsTab: some View {
        Group {
            if container.isRunning {
                ResourceMonitorView(containerId: container.id, containerName: container.displayName)
            } else {
                DDEmptyState(
                    icon: "chart.xyaxis.line",
                    title: "Container Stopped",
                    subtitle: "Start the container to view live resource usage statistics.",
                    actionTitle: "Start Container",
                    action: { Task { try? await service.startContainer(container.id) } }
                )
            }
        }
    }

    // MARK: - Info Tab

    private var infoTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DDTokens.space16) {
                // Container Details
                DDCard {
                    VStack(alignment: .leading, spacing: DDTokens.space4) {
                        infoSectionTitle("Container Details")

                        DDInfoRow(label: "Container ID", value: container.id, mono: true)
                        DDInfoRow(label: "Name", value: container.displayName)
                        DDInfoRow(label: "Image", value: container.image)
                        DDInfoRow(label: "Command", value: container.command, mono: true)
                        DDInfoRow(label: "Created", value: container.createdDate.formatted(.dateTime.month().day().year().hour().minute()))
                        DDInfoRow(label: "State", value: container.state.capitalized)
                        DDInfoRow(label: "Status", value: container.status)
                    }
                }

                // Compose info if available
                if container.composeProject != nil || container.composeService != nil {
                    DDCard {
                        VStack(alignment: .leading, spacing: DDTokens.space4) {
                            infoSectionTitle("Docker Compose")

                            if let project = container.composeProject {
                                DDInfoRow(label: "Project", value: project)
                            }
                            if let svc = container.composeService {
                                DDInfoRow(label: "Service", value: svc)
                            }
                        }
                    }
                }

                // Port mappings
                if let ports = container.ports, !ports.isEmpty {
                    DDCard {
                        VStack(alignment: .leading, spacing: DDTokens.space8) {
                            infoSectionTitle("Port Mappings")

                            ForEach(ports, id: \.privatePort) { port in
                                HStack(spacing: DDTokens.space10) {
                                    Image(systemName: "network")
                                        .font(.system(size: 12))
                                        .foregroundStyle(DDColors.brandBlue)
                                        .frame(width: 20)

                                    Text(port.displayString)
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundStyle(DDColors.textPrimary)

                                    Spacer()

                                    Text(port.type.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(DDColors.textTertiary)
                                        .padding(.horizontal, DDTokens.space6)
                                        .padding(.vertical, DDTokens.space2)
                                        .background(Color.primary.opacity(0.04), in: Capsule())
                                }
                                .padding(.vertical, DDTokens.space2)
                            }
                        }
                    }
                }
            }
            .padding(DDTokens.space20)
        }
    }

    // MARK: - Labels Tab

    private var labelsTab: some View {
        ScrollView {
            if let labels = container.labels, !labels.isEmpty {
                DDCard(padding: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header row
                        HStack {
                            Text("Key")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(DDColors.textTertiary)
                                .frame(width: 280, alignment: .leading)
                            Text("Value")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(DDColors.textTertiary)
                            Spacer()
                        }
                        .padding(.horizontal, DDTokens.space16)
                        .padding(.vertical, DDTokens.space10)
                        .background(Color.primary.opacity(0.02))

                        Divider().opacity(0.5)

                        ForEach(
                            labels.sorted(by: { $0.key < $1.key }),
                            id: \.key
                        ) { key, value in
                            VStack(spacing: 0) {
                                HStack(alignment: .top, spacing: DDTokens.space12) {
                                    Text(key)
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(DDColors.textPrimary)
                                        .frame(width: 268, alignment: .leading)
                                        .lineLimit(2)

                                    Text(value)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(DDColors.textSecondary)
                                        .lineLimit(3)
                                        .textSelection(.enabled)

                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, DDTokens.space16)
                                .padding(.vertical, DDTokens.space8)

                                Divider().opacity(0.3)
                            }
                        }
                    }
                }
                .padding(DDTokens.space20)
            } else {
                DDEmptyState(
                    icon: "tag",
                    title: "No Labels",
                    subtitle: "This container has no labels attached."
                )
            }
        }
    }

    // MARK: - Mounts Tab

    private var mountsTab: some View {
        ScrollView {
            if let mounts = container.mounts, !mounts.isEmpty {
                VStack(spacing: DDTokens.space12) {
                    ForEach(Array(mounts.enumerated()), id: \.offset) { _, mount in
                        DDCard {
                            VStack(alignment: .leading, spacing: DDTokens.space8) {
                                // Mount type badge
                                HStack {
                                    HStack(spacing: DDTokens.space4) {
                                        Image(systemName: mountIcon(mount.type))
                                            .font(.system(size: 12, weight: .medium))
                                        Text(mount.type?.capitalized ?? "Unknown")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundStyle(mountColor(mount.type))
                                    .padding(.horizontal, DDTokens.space8)
                                    .padding(.vertical, DDTokens.space4)
                                    .background(
                                        mountColor(mount.type).opacity(0.1),
                                        in: Capsule()
                                    )

                                    Spacer()

                                    // Read/Write indicator
                                    HStack(spacing: DDTokens.space4) {
                                        Circle()
                                            .fill(mount.rw == true ? DDColors.success : DDColors.warning)
                                            .frame(width: 6, height: 6)
                                        Text(mount.rw == true ? "Read/Write" : "Read Only")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(DDColors.textSecondary)
                                    }
                                }

                                if let src = mount.source {
                                    DDInfoRow(label: "Source", value: src, mono: true)
                                }
                                if let dst = mount.destination {
                                    DDInfoRow(label: "Destination", value: dst, mono: true)
                                }
                                if let name = mount.name {
                                    DDInfoRow(label: "Name", value: name, mono: true)
                                }
                                if let driver = mount.driver {
                                    DDInfoRow(label: "Driver", value: driver)
                                }
                            }
                        }
                    }
                }
                .padding(DDTokens.space20)
            } else {
                DDEmptyState(
                    icon: "externaldrive",
                    title: "No Mounts",
                    subtitle: "This container has no volumes or bind mounts configured."
                )
            }
        }
    }

    // MARK: - Helpers

    private func infoSectionTitle(_ title: String) -> some View {
        HStack(spacing: DDTokens.space6) {
            RoundedRectangle(cornerRadius: 1)
                .fill(DDColors.brandBlue)
                .frame(width: 3, height: 16)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DDColors.textPrimary)
        }
        .padding(.bottom, DDTokens.space4)
    }

    private func mountIcon(_ type: String?) -> String {
        switch type {
        case "bind":   return "folder"
        case "volume": return "externaldrive"
        case "tmpfs":  return "memorychip"
        default:       return "questionmark.circle"
        }
    }

    private func mountColor(_ type: String?) -> Color {
        switch type {
        case "bind":   return .orange
        case "volume": return DDColors.brandBlue
        case "tmpfs":  return .purple
        default:       return DDColors.textSecondary
        }
    }

    private func fetchLogs() async {
        isLoadingLogs = true
        do {
            logs = try await service.getContainerLogs(container.id, tail: 500)
        } catch {
            logs = "Error loading logs: \(error.localizedDescription)"
        }
        isLoadingLogs = false
    }
}
