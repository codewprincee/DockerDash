import SwiftUI

// MARK: - Color System

enum DDColors {
    static let brand = Color(red: 0.13, green: 0.59, blue: 0.95)    // Docker blue
    static let brandLight = Color(red: 0.22, green: 0.67, blue: 0.98)
    static let brandDark = Color(red: 0.08, green: 0.45, blue: 0.82)

    static let success = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let warning = Color(red: 1.0, green: 0.76, blue: 0.03)
    static let danger = Color(red: 0.94, green: 0.27, blue: 0.27)
    static let info = Color(red: 0.36, green: 0.54, blue: 0.98)

    // Container states
    static let running = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let stopped = Color(red: 0.64, green: 0.64, blue: 0.64)
    static let paused = Color(red: 1.0, green: 0.76, blue: 0.03)

    // Surfaces
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    static let sidebarBackground = Color(nsColor: .windowBackgroundColor)

    static func stateColor(_ state: String) -> Color {
        switch state {
        case "running": return running
        case "paused": return paused
        case "exited", "dead": return danger
        case "created": return info
        default: return stopped
        }
    }
}

// MARK: - Card Style

struct DDCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(16)
            .background(DDColors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator.opacity(0.5), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }
}

// MARK: - Status Pill

struct DDStatusPill: View {
    let state: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(DDColors.stateColor(state))
                .frame(width: 7, height: 7)

            if state == "running" {
                Circle()
                    .fill(DDColors.stateColor(state).opacity(0.3))
                    .frame(width: 7, height: 7)
                    .scaleEffect(1.8)
                    .overlay(
                        Circle()
                            .fill(DDColors.stateColor(state))
                            .frame(width: 7, height: 7)
                    )
            }

            Text(state.capitalized)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DDColors.stateColor(state))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(DDColors.stateColor(state).opacity(0.1), in: Capsule())
    }
}

// MARK: - Stat Card

struct DDStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        DDCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                        .frame(width: 32, height: 32)
                        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    Spacer()
                }
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Action Button

struct DDActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.medium))
        }
        .buttonStyle(.bordered)
        .tint(color)
        .controlSize(.small)
    }
}

// MARK: - Empty State (redesigned)

struct DDEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.quaternary.opacity(0.5))
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(.tertiary)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Section Header

struct DDSectionHeader: View {
    let title: String
    var count: Int?
    var trailing: AnyView?

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            if let count {
                Text("(\(count))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            trailing
        }
    }

    init(_ title: String, count: Int? = nil) {
        self.title = title
        self.count = count
        self.trailing = nil
    }
}

// MARK: - Docker Logo

struct DockerLogo: View {
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: "shippingbox.fill")
            .font(.system(size: size))
            .foregroundStyle(DDColors.brand)
    }
}
