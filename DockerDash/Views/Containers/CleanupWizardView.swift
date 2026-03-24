import SwiftUI

struct CleanupWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var stoppedContainers: [DockerContainer] = []
    @State private var danglingImages: [DockerImage] = []
    @State private var unusedVolumes: [DockerVolume] = []
    @State private var isLoading = true
    @State private var isCleaningContainers = false
    @State private var isCleaningImages = false
    @State private var isCleaningVolumes = false
    @State private var spaceSaved: Int64 = 0
    @State private var resultMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "trash.circle.fill")
                    .font(.title2).foregroundStyle(.red)
                Text("Cleanup Wizard").font(.title3.bold())
                Spacer()
                Button("Close") { dismiss() }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            if isLoading {
                LoadingStateView(message: "Scanning for unused resources...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Stopped containers
                        cleanupSection(
                            title: "Stopped Containers",
                            icon: "shippingbox",
                            count: stoppedContainers.count,
                            description: stoppedContainers.map(\.displayName).joined(separator: ", "),
                            isCleaning: isCleaningContainers,
                            action: pruneContainers
                        )

                        // Dangling images
                        cleanupSection(
                            title: "Dangling Images",
                            icon: "photo.stack",
                            count: danglingImages.count,
                            description: totalSize(danglingImages.map(\.size)),
                            isCleaning: isCleaningImages,
                            action: pruneImages
                        )

                        // Unused volumes
                        cleanupSection(
                            title: "Unused Volumes",
                            icon: "externaldrive",
                            count: unusedVolumes.count,
                            description: unusedVolumes.map(\.name).prefix(5).joined(separator: ", "),
                            isCleaning: isCleaningVolumes,
                            action: pruneVolumes
                        )

                        // Results
                        if let msg = resultMessage {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                Text(msg).font(.body.bold())
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }

                        if spaceSaved > 0 {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill").foregroundStyle(.blue)
                                Text("Total space saved: \(ByteCountFormatter.string(fromByteCount: spaceSaved, countStyle: .file))")
                                    .font(.body.bold())
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }

                        // Clean All button
                        if stoppedContainers.count + danglingImages.count + unusedVolumes.count > 0 {
                            Button(action: { Task { await cleanAll() } }) {
                                Label("Clean Everything", systemImage: "trash.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .controlSize(.large)
                        } else if resultMessage == nil {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Everything is clean! No unused resources found.")
                            }
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 520, height: 550)
        .task { await scan() }
    }

    private func cleanupSection(title: String, icon: String, count: Int, description: String, isCleaning: Bool, action: @escaping () async -> Void) -> some View {
        GroupBox {
            HStack {
                Image(systemName: icon).font(.title3).foregroundStyle(.secondary).frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body.weight(.medium))
                    if count > 0 {
                        Text("\(count) items — \(description)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    } else {
                        Text("None found").font(.caption).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                if count > 0 {
                    if isCleaning {
                        ProgressView().controlSize(.small)
                    } else {
                        Button("Remove") { Task { await action() } }
                            .buttonStyle(.bordered).controlSize(.small)
                    }
                } else {
                    Image(systemName: "checkmark.circle").foregroundStyle(.green)
                }
            }
        }
    }

    private func scan() async {
        isLoading = true
        do {
            let allContainers: [DockerContainer] = try await DockerAPIClient.shared.get("/containers/json?all=true")
            stoppedContainers = allContainers.filter(\.isStopped)

            let allImages: [DockerImage] = try await DockerAPIClient.shared.get("/images/json?filters={\"dangling\":[\"true\"]}")
            danglingImages = allImages

            let volResponse: VolumesResponse = try await DockerAPIClient.shared.get("/volumes?filters={\"dangling\":[\"true\"]}")
            unusedVolumes = volResponse.volumes ?? []
        } catch {}
        isLoading = false
    }

    private func pruneContainers() async {
        isCleaningContainers = true
        for c in stoppedContainers {
            try? await DockerAPIClient.shared.delete("/containers/\(c.id)?force=true")
        }
        let count = stoppedContainers.count
        stoppedContainers = []
        isCleaningContainers = false
        resultMessage = "Removed \(count) stopped containers"
    }

    private func pruneImages() async {
        isCleaningImages = true
        let size = danglingImages.reduce(0) { $0 + Int64($1.size) }
        for img in danglingImages {
            try? await DockerAPIClient.shared.delete("/images/\(img.id)?force=true")
        }
        spaceSaved += size
        danglingImages = []
        isCleaningImages = false
        resultMessage = "Removed dangling images"
    }

    private func pruneVolumes() async {
        isCleaningVolumes = true
        for vol in unusedVolumes {
            try? await DockerAPIClient.shared.delete("/volumes/\(vol.name)")
        }
        let count = unusedVolumes.count
        unusedVolumes = []
        isCleaningVolumes = false
        resultMessage = "Removed \(count) unused volumes"
    }

    private func cleanAll() async {
        await pruneContainers()
        await pruneImages()
        await pruneVolumes()
        resultMessage = "All cleanup complete!"
    }

    private func totalSize(_ sizes: [Int]) -> String {
        let total = sizes.reduce(0, +)
        return ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .file)
    }
}
