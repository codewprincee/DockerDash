import Foundation

@Observable
final class ContainerService {
    var containers: [DockerContainer] = []
    var isLoading = false
    var error: String?

    var runningCount: Int { containers.filter(\.isRunning).count }
    var stoppedCount: Int { containers.filter(\.isStopped).count }

    func fetchContainers() async {
        isLoading = containers.isEmpty
        do {
            let result: [DockerContainer] = try await DockerAPIClient.shared.get("/containers/json?all=true")
            await MainActor.run {
                containers = result
                error = nil
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }

    func startContainer(_ id: String) async throws {
        try await DockerAPIClient.shared.postNoContent("/containers/\(id)/start")
        await fetchContainers()
    }

    func stopContainer(_ id: String) async throws {
        try await DockerAPIClient.shared.postNoContent("/containers/\(id)/stop")
        await fetchContainers()
    }

    func restartContainer(_ id: String) async throws {
        try await DockerAPIClient.shared.postNoContent("/containers/\(id)/restart")
        await fetchContainers()
    }

    func removeContainer(_ id: String, force: Bool = false) async throws {
        try await DockerAPIClient.shared.delete("/containers/\(id)?force=\(force)")
        await fetchContainers()
    }

    func getContainerLogs(_ id: String, tail: Int = 200) async throws -> String {
        try await DockerAPIClient.shared.getRawString("/containers/\(id)/logs?stdout=true&stderr=true&timestamps=true&tail=\(tail)")
    }
}
