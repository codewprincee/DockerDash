import SwiftUI

// MARK: - Design Tokens

/// Central design system for DockerDash. Every color, spacing value,
/// and reusable component lives here so the rest of the app stays
/// consistent without duplicating magic numbers.
enum DDTokens {

    // MARK: Spacing (4-pt grid)

    static let space2:  CGFloat = 2
    static let space4:  CGFloat = 4
    static let space6:  CGFloat = 6
    static let space8:  CGFloat = 8
    static let space10: CGFloat = 10
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space20: CGFloat = 20
    static let space24: CGFloat = 24
    static let space32: CGFloat = 32
    static let space40: CGFloat = 40
    static let space48: CGFloat = 48

    // MARK: Corner Radii

    static let radiusSm:  CGFloat = 6
    static let radiusMd:  CGFloat = 10
    static let radiusLg:  CGFloat = 14
    static let radiusXl:  CGFloat = 20

    // MARK: Animation

    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let easeOut      = Animation.easeOut(duration: 0.2)
}

// MARK: - Color System (Light + Dark adaptive)

enum DDColors {

    // Brand
    static let brand      = Color.accentColor
    static let brandBlue  = Color(red: 0.141, green: 0.588, blue: 0.929) // #2496ED
    static let brandLight = Color(red: 0.306, green: 0.682, blue: 0.965)
    static let brandDark  = Color(red: 0.098, green: 0.451, blue: 0.816)

    // Semantic
    static let success = Color(red: 0.133, green: 0.773, blue: 0.369) // vibrant green
    static let warning = Color(red: 0.976, green: 0.729, blue: 0.063) // amber
    static let danger  = Color(red: 0.918, green: 0.263, blue: 0.208) // red
    static let info    = Color(red: 0.353, green: 0.537, blue: 0.976) // periwinkle

    // Container states
    static let running = success
    static let stopped = Color(nsColor: .tertiaryLabelColor)
    static let paused  = warning

    // Surface hierarchy — these adapt automatically in light/dark
    static let cardBackground       = Color(nsColor: .controlBackgroundColor)
    static let cardBackgroundRaised = Color(nsColor: .windowBackgroundColor)
    static let sidebarBackground    = Color(nsColor: .windowBackgroundColor)
    static let groupedBackground    = Color(nsColor: .underPageBackgroundColor)
    static let codeBackground       = Color(nsColor: .textBackgroundColor)

    // Text hierarchy
    static let textPrimary   = Color(nsColor: .labelColor)
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    static let textTertiary  = Color(nsColor: .tertiaryLabelColor)
    static let textQuaternary = Color(nsColor: .quaternaryLabelColor)

    // Borders
    static let border       = Color(nsColor: .separatorColor)
    static let borderSubtle = Color(nsColor: .separatorColor).opacity(0.5)

    // Helper
    static func stateColor(_ state: String) -> Color {
        switch state {
        case "running":         return running
        case "paused":          return paused
        case "exited", "dead":  return danger
        case "created":         return info
        case "restarting":      return warning
        default:                return stopped
        }
    }

    static func stateLabel(_ state: String) -> String {
        switch state {
        case "running":    return "Running"
        case "paused":     return "Paused"
        case "exited":     return "Exited"
        case "dead":       return "Dead"
        case "created":    return "Created"
        case "restarting": return "Restarting"
        default:           return state.capitalized
        }
    }
}

// MARK: - Shadows

enum DDShadow {
    static func card(_ scheme: ColorScheme) -> some View {
        Color.black
            .opacity(scheme == .dark ? 0.25 : 0.06)
            .blur(radius: scheme == .dark ? 8 : 5)
            .offset(y: 2)
    }
}

// MARK: - Card Component

struct DDCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    var padding: CGFloat = DDTokens.space16
    let content: () -> Content

    init(padding: CGFloat = DDTokens.space16, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: DDTokens.radiusLg, style: .continuous)
                    .fill(DDColors.cardBackground)
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06),
                        radius: colorScheme == .dark ? 8 : 4,
                        y: colorScheme == .dark ? 4 : 2
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: DDTokens.radiusLg, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark
                            ? Color.white.opacity(0.06)
                            : Color.black.opacity(0.04),
                        lineWidth: 0.5
                    )
            }
    }
}

// MARK: - Glass Card (for prominent areas like the dashboard header)

struct DDGlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(DDTokens.space20)
            .background {
                RoundedRectangle(cornerRadius: DDTokens.radiusLg, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.35 : 0.08),
                        radius: 12, y: 4
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: DDTokens.radiusLg, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.12 : 0.6),
                                Color.white.opacity(colorScheme == .dark ? 0.04 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
    }
}

// MARK: - Status Pill

struct DDStatusPill: View {
    let state: String
    var compact: Bool = false

    private var color: Color { DDColors.stateColor(state) }
    private var label: String { DDColors.stateLabel(state) }

    var body: some View {
        HStack(spacing: DDTokens.space4) {
            // Animated pulsing dot for running containers
            ZStack {
                if state == "running" {
                    Circle()
                        .fill(color.opacity(0.35))
                        .frame(width: 12, height: 12)
                        .modifier(PulseAnimation())
                }
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
            }
            .frame(width: 12, height: 12)

            if !compact {
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
            }
        }
        .padding(.horizontal, compact ? DDTokens.space4 : DDTokens.space8)
        .padding(.vertical, DDTokens.space4)
        .background(color.opacity(0.12), in: Capsule())
    }
}

private struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.6 : 1.0)
            .opacity(isPulsing ? 0 : 0.6)
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

// MARK: - Stat Card (for dashboard overview)

struct DDStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
        DDCard {
            VStack(alignment: .leading, spacing: DDTokens.space10) {
                HStack(alignment: .top) {
                    // Icon badge
                    ZStack {
                        RoundedRectangle(cornerRadius: DDTokens.radiusSm, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.2), color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(color)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: DDTokens.space2) {
                    Text(value)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(DDColors.textPrimary)
                        .contentTransition(.numericText())

                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DDColors.textSecondary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(DDColors.textTertiary)
                    }
                }
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(DDTokens.springSnappy, value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Port Pill

struct DDPortPill: View {
    let port: Int
    var type: String = "tcp"

    var body: some View {
        HStack(spacing: DDTokens.space2) {
            Image(systemName: "network")
                .font(.system(size: 8, weight: .bold))
            Text(":\(port)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
        }
        .foregroundStyle(DDColors.brandBlue)
        .padding(.horizontal, DDTokens.space6)
        .padding(.vertical, DDTokens.space2)
        .background(DDColors.brandBlue.opacity(0.1), in: Capsule())
    }
}

// MARK: - Action Button (icon-only, shows on hover)

struct DDIconButton: View {
    let icon: String
    let color: Color
    let help: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isHovered ? .white : color)
                .frame(width: 26, height: 26)
                .background(
                    isHovered ? color : color.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: DDTokens.radiusSm, style: .continuous)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovered = $0 }
        .animation(DDTokens.easeOut, value: isHovered)
    }
}

// MARK: - Action Button (labeled)

struct DDActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .medium))
        }
        .buttonStyle(.bordered)
        .tint(color)
        .controlSize(.small)
    }
}

// MARK: - Empty State (premium feel)

struct DDEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String?
    var action: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: DDTokens.space24) {
            Spacer()

            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DDColors.brandBlue.opacity(0.08),
                                DDColors.brandBlue.opacity(0.02),
                                .clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                // Inner circle
                Circle()
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.04)
                            : Color.black.opacity(0.03)
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(DDColors.textTertiary)
            }

            VStack(spacing: DDTokens.space8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(DDColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(DDColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(DDColors.brandBlue)
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
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DDColors.textPrimary)
            if let count {
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(DDColors.textTertiary)
                    .padding(.horizontal, DDTokens.space6)
                    .padding(.vertical, DDTokens.space2)
                    .background(DDColors.textQuaternary.opacity(0.2), in: Capsule())
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
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [DDColors.brandBlue, DDColors.brandDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            Image(systemName: "shippingbox.fill")
                .font(.system(size: size * 0.52, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Info Row (for detail views)

struct DDInfoRow: View {
    let label: String
    let value: String
    var mono: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: DDTokens.space12) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DDColors.textTertiary)
                .frame(width: 110, alignment: .trailing)

            Text(value)
                .font(mono
                    ? .system(size: 12, weight: .regular, design: .monospaced)
                    : .system(size: 12, weight: .medium)
                )
                .foregroundStyle(DDColors.textPrimary)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
        .padding(.vertical, DDTokens.space4)
    }
}

// MARK: - Tab Button (for detail view tabs)

struct DDTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DDTokens.space6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isSelected ? DDColors.brandBlue : DDColors.textSecondary)
            .padding(.horizontal, DDTokens.space12)
            .padding(.vertical, DDTokens.space8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DDTokens.radiusSm, style: .continuous)
                        .fill(DDColors.brandBlue.opacity(0.1))
                } else if isHovered {
                    RoundedRectangle(cornerRadius: DDTokens.radiusSm, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                }
            }
            .overlay(alignment: .bottom) {
                if isSelected {
                    Capsule()
                        .fill(DDColors.brandBlue)
                        .frame(height: 2)
                        .padding(.horizontal, DDTokens.space4)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(DDTokens.easeOut, value: isSelected)
        .animation(DDTokens.easeOut, value: isHovered)
    }
}

// MARK: - Search Field

struct DDSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search..."

    var body: some View {
        HStack(spacing: DDTokens.space6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DDColors.textTertiary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(DDColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DDTokens.space10)
        .padding(.vertical, DDTokens.space6)
        .background(
            RoundedRectangle(cornerRadius: DDTokens.radiusSm, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DDTokens.radiusSm, style: .continuous)
                .strokeBorder(DDColors.borderSubtle, lineWidth: 0.5)
        )
    }
}

// MARK: - Filter Chip

struct DDFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : DDColors.textSecondary)
                .padding(.horizontal, DDTokens.space12)
                .padding(.vertical, DDTokens.space6)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(DDColors.brandBlue)
                    } else {
                        Capsule()
                            .fill(isHovered ? Color.primary.opacity(0.06) : Color.primary.opacity(0.03))
                    }
                }
                .overlay {
                    if !isSelected {
                        Capsule()
                            .strokeBorder(DDColors.borderSubtle, lineWidth: 0.5)
                    }
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(DDTokens.easeOut, value: isSelected)
        .animation(DDTokens.easeOut, value: isHovered)
    }
}
