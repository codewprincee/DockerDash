import Foundation

@Observable
final class SystemService {
    var systemInfo: DockerSystemInfo?
    var version: DockerVersion?
    var isConnected = false
    var error: String?

    func checkConnection() async -> Bool {
        do {
            let ok = try await DockerAPIClient.shared.ping()
            await MainActor.run { isConnected = ok; error = nil }
            return ok
        } catch {
            await MainActor.run { isConnected = false; self.error = error.localizedDescription }
            return false
        }
    }

    func fetchInfo() async {
        do {
            async let info: DockerSystemInfo = DockerAPIClient.shared.get("/info")
            async let ver: DockerVersion = DockerAPIClient.shared.get("/version")
            let (i, v) = try await (info, ver)
            await MainActor.run { systemInfo = i; version = v }
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
        }
    }
}
