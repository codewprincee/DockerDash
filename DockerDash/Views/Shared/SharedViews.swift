import SwiftUI

// MARK: - Container Status Badge (legacy compat, used in Compose and ResourceMonitor)

struct ContainerStatusBadge: View {
    let state: String

    var body: some View {
        DDStatusPill(state: state, compact: false)
    }
}

// MARK: - Loading State

struct LoadingStateView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: DDTokens.space16) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DDColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error State

struct ErrorStateView: View {
    let message: String
    var onRetry: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: DDTokens.space16) {
            ZStack {
                Circle()
                    .fill(DDColors.danger.opacity(0.1))
                    .frame(width: 64, height: 64)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(DDColors.danger)
            }

            VStack(spacing: DDTokens.space6) {
                Text("Something Went Wrong")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DDColors.textPrimary)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(DDColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            if let onRetry {
                Button("Try Again", action: onRetry)
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DDTokens.space20)
    }
}

// MARK: - Empty State (legacy compat, wraps DDEmptyState)

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        DDEmptyState(
            icon: systemImage,
            title: title,
            subtitle: subtitle
        )
    }
}

// MARK: - Docker Not Running

struct DockerNotRunningView: View {
    var onRetry: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: DDTokens.space32) {
            Spacer()

            // Icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DDColors.brandBlue.opacity(0.1),
                                DDColors.brandBlue.opacity(0.02),
                                .clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.04)
                            : Color.black.opacity(0.03)
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "shippingbox.circle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(DDColors.textQuaternary)
            }

            VStack(spacing: DDTokens.space8) {
                Text("Docker Not Running")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(DDColors.textPrimary)

                Text("DockerDash needs Docker Engine to be running.\nStart Docker Desktop and try again.")
                    .font(.system(size: 14))
                    .foregroundStyle(DDColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Button(action: onRetry) {
                HStack(spacing: DDTokens.space6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Retry Connection")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(DDColors.brandBlue)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
