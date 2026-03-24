import SwiftUI

struct VolumeListView: View {
    @State private var volumeService = VolumeService()

    var body: some View {
        Group {
            if volumeService.isLoading && volumeService.volumes.isEmpty {
                LoadingStateView()
            } else if volumeService.volumes.isEmpty {
                EmptyStateView(title: "No Volumes", subtitle: "No Docker volumes found.", systemImage: "externaldrive")
            } else {
                List(volumeService.volumes) { volume in
                    HStack {
                        Image(systemName: "externaldrive").foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(volume.name).font(.body.weight(.medium)).lineLimit(1)
                            Text(volume.driver).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(volume.scope ?? "local").font(.caption2).foregroundStyle(.tertiary)
                    }
                    .contextMenu {
                        Button("Remove", role: .destructive) {
                            Task { try? await volumeService.removeVolume(volume.name) }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Volumes (\(volumeService.volumes.count))")
        .task { await volumeService.fetchVolumes() }
    }
}
