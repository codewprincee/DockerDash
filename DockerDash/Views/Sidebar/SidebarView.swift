import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var containerService = ContainerService()
    @State private var hoveredSection: AppState.SidebarSection?

    // Sections grouped logically
    private let mainSections: [AppState.SidebarSection] = [
        .dashboard, .containers, .images, .volumes, .networks, .ports, .compose
    ]
    private let toolSections: [AppState.SidebarSection] = [.cleanup]

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // MARK: - App Header
            sidebarHeader

            Divider()
                .padding(.horizontal, DDTokens.space12)
                .opacity(0.5)

            // MARK: - Navigation
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: DDTokens.space4) {

                    sectionLabel("NAVIGATION")

                    ForEach(mainSections) { section in
                        sidebarRow(section)
                    }

                    sectionLabel("TOOLS")
                        .padding(.top, DDTokens.space8)

                    ForEach(toolSections) { section in
                        sidebarRow(section)
                    }
                }
                .padding(.horizontal, DDTokens.space12)
                .padding(.vertical, DDTokens.space8)
            }

            Spacer(minLength: 0)

            Divider()
                .padding(.horizontal, DDTokens.space12)
                .opacity(0.5)

            // MARK: - Settings at Bottom
            VStack(spacing: 0) {
                sidebarRow(.settings)
            }
            .padding(.horizontal, DDTokens.space12)
            .padding(.vertical, DDTokens.space8)
        }
        .listStyle(.sidebar)
        .task {
            await containerService.fetchContainers()
        }
    }

    // MARK: - Header

    private var sidebarHeader: some View {
        HStack(spacing: DDTokens.space10) {
            DockerLogo(size: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text("DockerDash")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(DDColors.textPrimary)
                Text("Container Manager")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DDColors.textTertiary)
            }

            Spacer(minLength: 0)

            // Connection indicator
            HStack(spacing: DDTokens.space4) {
                Circle()
                    .fill(appState.isDockerConnected ? DDColors.success : DDColors.danger)
                    .frame(width: 7, height: 7)
                    .shadow(
                        color: (appState.isDockerConnected ? DDColors.success : DDColors.danger).opacity(0.5),
                        radius: 3
                    )
            }
        }
        .padding(.horizontal, DDTokens.space16)
        .padding(.vertical, DDTokens.space12)
    }

    // MARK: - Section Label

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(DDColors.textQuaternary)
            .tracking(0.8)
            .padding(.horizontal, DDTokens.space8)
            .padding(.top, DDTokens.space4)
            .padding(.bottom, DDTokens.space2)
    }

    // MARK: - Row

    private func sidebarRow(_ section: AppState.SidebarSection) -> some View {
        let isSelected = appState.selectedSection == section
        let isHovered = hoveredSection == section

        return Button {
            withAnimation(DDTokens.springSnappy) {
                appState.selectedSection = section
            }
        } label: {
            HStack(spacing: DDTokens.space10) {
                // Icon with color
                Image(systemName: iconName(section))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : iconColor(section))
                    .frame(width: 28, height: 28)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: DDTokens.radiusSm, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [iconColor(section), iconColor(section).opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: iconColor(section).opacity(0.3), radius: 4, y: 2)
                        } else {
                            RoundedRectangle(cornerRadius: DDTokens.radiusSm, style: .continuous)
                                .fill(iconColor(section).opacity(isHovered ? 0.15 : 0.08))
                        }
                    }

                // Title
                Text(section.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? DDColors.textPrimary : DDColors.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                // Running count badge for containers
                if section == .containers && containerService.runningCount > 0 {
                    Text("\(containerService.runningCount)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, DDTokens.space6)
                        .padding(.vertical, DDTokens.space2)
                        .background(
                            Capsule()
                                .fill(DDColors.success)
                                .shadow(color: DDColors.success.opacity(0.3), radius: 2, y: 1)
                        )
                }
            }
            .padding(.horizontal, DDTokens.space8)
            .padding(.vertical, DDTokens.space6)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DDTokens.radiusMd, style: .continuous)
                        .fill(
                            colorScheme == .dark
                                ? Color.white.opacity(0.06)
                                : Color.black.opacity(0.04)
                        )
                } else if isHovered {
                    RoundedRectangle(cornerRadius: DDTokens.radiusMd, style: .continuous)
                        .fill(
                            colorScheme == .dark
                                ? Color.white.opacity(0.03)
                                : Color.black.opacity(0.02)
                        )
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: DDTokens.radiusMd))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DDTokens.easeOut) {
                hoveredSection = hovering ? section : nil
            }
        }
    }

    // MARK: - Icons (using reliable SF Symbols)

    private func iconName(_ section: AppState.SidebarSection) -> String {
        switch section {
        case .dashboard:  return "square.grid.2x2.fill"
        case .containers: return "shippingbox.fill"
        case .images:     return "photo.stack.fill"
        case .volumes:    return "externaldrive.fill"
        case .networks:   return "network"
        case .ports:      return "arrow.left.arrow.right"
        case .compose:    return "rectangle.3.group.fill"
        case .cleanup:    return "trash.circle.fill"
        case .settings:   return "gearshape.fill"
        }
    }

    private func iconColor(_ section: AppState.SidebarSection) -> Color {
        switch section {
        case .dashboard:  return DDColors.brandBlue
        case .containers: return .blue
        case .images:     return .purple
        case .volumes:    return .orange
        case .networks:   return .cyan
        case .ports:      return .indigo
        case .compose:    return .pink
        case .cleanup:    return .red
        case .settings:   return .gray
        }
    }
}
