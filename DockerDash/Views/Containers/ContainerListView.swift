import SwiftUI

enum ContainerAction { case start, stop, restart, remove }

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
                // MARK: - Toolbar Area
                VStack(spacing: DDTokens.space10) {
                    // Filter chips
                    HStack(spacing: DDTokens.space6) {
                        ForEach(ContainerFilter.allCases, id: \.self) { f in
                            DDFilterChip(
                                title: filterLabel(f),
                                isSelected: filter == f
                            ) {
                                withAnimation(DDTokens.springSnappy) { filter = f }
                            }
                        }
                        Spacer()
                    }

                    // Search
                    DDSearchField(text: $searchText, placeholder: "Search containers...")
                }
                .padding(.horizontal, DDTokens.space16)
                .padding(.vertical, DDTokens.space12)
                .background(.bar)

                Divider().opacity(0.5)

                // MARK: - Container List
                if containerService.isLoading && containerService.containers.isEmpty {
                    LoadingStateView()
                } else if filtered.isEmpty {
                    DDEmptyState(
                        icon: "shippingbox",
                        title: "No Containers",
                        subtitle: "No containers match your current filter. Try changing the filter or search query."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: DDTokens.space6) {
                            ForEach(filtered) { container in
                                ContainerRowView(
                                    container: container,
                                    isSelected: selectedContainer?.id == container.id,
                                    onSelect: {
                                        withAnimation(DDTokens.springSnappy) {
                                            selectedContainer = container
                                        }
                                    },
                                    onAction: { action in
                                        Task { await performAction(action, on: container) }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, DDTokens.space12)
                        .padding(.vertical, DDTokens.space8)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 340, ideal: 420, max: 520)
        } detail: {
            if let container = selectedContainer {
                ContainerDetailView(container: container, service: containerService)
            } else {
                DDEmptyState(
                    icon: "shippingbox",
                    title: "Select a Container",
                    subtitle: "Choose a container from the list to inspect its logs, stats, configuration, and more."
                )
            }
        }
        .navigationTitle("Containers")
        .navigationSubtitle("\(containerService.runningCount) running")
        .task {
            await containerService.fetchContainers()
            polling.startPolling(id: "containers", interval: 3) {
                await containerService.fetchContainers()
            }
        }
        .onDisappear { polling.stopAll() }
    }

    private func filterLabel(_ f: ContainerFilter) -> String {
        let count: Int
        switch f {
        case .all:     count = containerService.containers.count
        case .running: count = containerService.runningCount
        case .stopped: count = containerService.stoppedCount
        }
        return "\(f.rawValue) (\(count))"
    }

    private func performAction(_ action: ContainerAction, on container: DockerContainer) async {
        do {
            switch action {
            case .start:   try await containerService.startContainer(container.id)
            case .stop:    try await containerService.stopContainer(container.id)
            case .restart: try await containerService.restartContainer(container.id)
            case .remove:
                if selectedContainer?.id == container.id { selectedContainer = nil }
                try await containerService.removeContainer(container.id, force: true)
            }
        } catch {
            // Error handling managed by service layer
        }
    }
}

// MARK: - Container Row

struct ContainerRowView: View {
    let container: DockerContainer
    let isSelected: Bool
    let onSelect: () -> Void
    var onAction: (ContainerAction) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    private var publicPorts: [Int] {
        container.ports?.compactMap(\.publicPort) ?? []
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DDTokens.space12) {
                // Status indicator
                DDStatusPill(state: container.state, compact: true)
                    .frame(width: 26)

                // Main content
                VStack(alignment: .leading, spacing: DDTokens.space4) {
                    // Row 1: Name
                    HStack(spacing: DDTokens.space8) {
                        Text(container.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DDColors.textPrimary)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        // Status time
                        Text(container.status)
                            .font(.system(size: 11))
                            .foregroundStyle(DDColors.textTertiary)
                            .lineLimit(1)
                    }

                    // Row 2: Image + Ports
                    HStack(spacing: DDTokens.space6) {
                        // Image name
                        HStack(spacing: DDTokens.space4) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 9))
                                .foregroundStyle(DDColors.textQuaternary)
                            Text(container.image)
                                .font(.system(size: 11))
                                .foregroundStyle(DDColors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        // Port pills
                        if !publicPorts.isEmpty {
                            HStack(spacing: DDTokens.space4) {
                                ForEach(publicPorts.prefix(3), id: \.self) { port in
                                    DDPortPill(port: port)
                                }
                                if publicPorts.count > 3 {
                                    Text("+\(publicPorts.count - 3)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(DDColors.textTertiary)
                                }
                            }
                        }
                    }
                }

                // Hover action buttons
                if isHovered {
                    HStack(spacing: DDTokens.space4) {
                        if container.isRunning {
                            DDIconButton(icon: "stop.fill", color: DDColors.danger, help: "Stop") {
                                onAction(.stop)
                            }
                        }
                        if container.isStopped {
                            DDIconButton(icon: "play.fill", color: DDColors.success, help: "Start") {
                                onAction(.start)
                            }
                        }
                        DDIconButton(icon: "arrow.clockwise", color: DDColors.brandBlue, help: "Restart") {
                            onAction(.restart)
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .padding(.horizontal, DDTokens.space12)
            .padding(.vertical, DDTokens.space10)
            .background {
                RoundedRectangle(cornerRadius: DDTokens.radiusMd, style: .continuous)
                    .fill(rowBackground)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: DDTokens.radiusMd, style: .continuous)
                        .strokeBorder(DDColors.brandBlue.opacity(0.4), lineWidth: 1.5)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: DDTokens.radiusMd, style: .continuous)
                        .strokeBorder(DDColors.borderSubtle, lineWidth: 0.5)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: DDTokens.radiusMd))
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            withAnimation(DDTokens.easeOut) { isHovered = hovered }
        }
        .contextMenu {
            if container.isStopped {
                Button { onAction(.start) } label: {
                    Label("Start", systemImage: "play.fill")
                }
            }
            if container.isRunning {
                Button { onAction(.stop) } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
            }
            Button { onAction(.restart) } label: {
                Label("Restart", systemImage: "arrow.clockwise")
            }
            Divider()
            Button(role: .destructive) { onAction(.remove) } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var rowBackground: Color {
        if isSelected {
            return colorScheme == .dark
                ? DDColors.brandBlue.opacity(0.12)
                : DDColors.brandBlue.opacity(0.06)
        }
        if isHovered {
            return colorScheme == .dark
                ? Color.white.opacity(0.03)
                : Color.black.opacity(0.02)
        }
        return .clear
    }
}
