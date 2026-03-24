import Foundation

@Observable
final class VolumeService {
    var volumes: [DockerVolume] = []
    var isLoading = false
    var error: String?

    func fetchVolumes() async {
        isLoading = volumes.isEmpty
        do {
            let response: VolumesResponse = try await DockerAPIClient.shared.get("/volumes")
            await MainActor.run {
                volumes = response.volumes ?? []
                error = nil; isLoading = false
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription; isLoading = false }
        }
    }

    func removeVolume(_ name: String) async throws {
        try await DockerAPIClient.shared.delete("/volumes/\(name)")
        await fetchVolumes()
    }
}
