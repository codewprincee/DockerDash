import Foundation

@Observable
final class NetworkService {
    var networks: [DockerNetwork] = []
    var isLoading = false
    var error: String?

    func fetchNetworks() async {
        isLoading = networks.isEmpty
        do {
            let result: [DockerNetwork] = try await DockerAPIClient.shared.get("/networks")
            await MainActor.run {
                networks = result
                error = nil; isLoading = false
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription; isLoading = false }
        }
    }

    func removeNetwork(_ id: String) async throws {
        try await DockerAPIClient.shared.delete("/networks/\(id)")
        await fetchNetworks()
    }
}
