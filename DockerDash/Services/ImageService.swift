import Foundation

@Observable
final class ImageService {
    var images: [DockerImage] = []
    var isLoading = false
    var error: String?

    func fetchImages() async {
        isLoading = images.isEmpty
        do {
            let result: [DockerImage] = try await DockerAPIClient.shared.get("/images/json")
            await MainActor.run {
                images = result.sorted { $0.created > $1.created }
                error = nil
                isLoading = false
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription; isLoading = false }
        }
    }

    func removeImage(_ id: String, force: Bool = false) async throws {
        try await DockerAPIClient.shared.delete("/images/\(id)?force=\(force)")
        await fetchImages()
    }

    func pullImage(name: String, tag: String = "latest") async throws {
        let _: EmptyDockerResponse = try await DockerAPIClient.shared.post("/images/create?fromImage=\(name)&tag=\(tag)")
        await fetchImages()
    }
}

struct EmptyDockerResponse: Codable {}
