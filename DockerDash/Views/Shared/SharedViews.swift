import SwiftUI

struct ContainerStatusBadge: View {
    let state: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(stateColor).frame(width: 8, height: 8)
            Text(state).font(.caption2.bold()).foregroundStyle(stateColor)
        }
    }
    private var stateColor: Color {
        switch state {
        case "running": return .green
        case "paused": return .yellow
        case "exited", "dead": return .red
        case "created": return .blue
        default: return .gray
        }
    }
}

struct LoadingStateView: View {
    var message: String = "Loading..."
    var body: some View {
        VStack(spacing: 12) { ProgressView(); Text(message).font(.caption).foregroundStyle(.secondary) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorStateView: View {
    let message: String; var onRetry: (() -> Void)?
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(.red)
            Text(message).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let onRetry { Button("Retry", action: onRetry).buttonStyle(.bordered) }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding()
    }
}

struct EmptyStateView: View {
    let title: String; let subtitle: String; let systemImage: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage).font(.system(size: 40)).foregroundStyle(.quaternary)
            Text(title).font(.title3.weight(.medium)).foregroundStyle(.secondary)
            Text(subtitle).font(.body).foregroundStyle(.tertiary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding()
    }
}

struct DockerNotRunningView: View {
    var onRetry: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "shippingbox.circle")
                .font(.system(size: 72)).foregroundStyle(.quaternary)
            Text("Docker Not Running").font(.title.bold())
            Text("Start Docker Desktop and try again.")
                .font(.body).foregroundStyle(.secondary)
            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent).controlSize(.large)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
