import SwiftUI

struct NetworkListView: View {
    @State private var networkService = NetworkService()

    var body: some View {
        Group {
            if networkService.isLoading && networkService.networks.isEmpty {
                LoadingStateView()
            } else if networkService.networks.isEmpty {
                EmptyStateView(title: "No Networks", subtitle: "No Docker networks found.", systemImage: "network")
            } else {
                List(networkService.networks) { network in
                    HStack {
                        Image(systemName: "network").foregroundStyle(.cyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(network.name).font(.body.weight(.medium))
                            Text(network.driver).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(network.containerCount) containers").font(.caption2).foregroundStyle(.tertiary)
                        Text(network.scope).font(.caption2).padding(.horizontal, 4).padding(.vertical, 1)
                            .background(.quaternary, in: Capsule())
                    }
                    .contextMenu {
                        if network.name != "bridge" && network.name != "host" && network.name != "none" {
                            Button("Remove", role: .destructive) {
                                Task { try? await networkService.removeNetwork(network.id) }
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Networks (\(networkService.networks.count))")
        .task { await networkService.fetchNetworks() }
    }
}
