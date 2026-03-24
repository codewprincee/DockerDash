import Foundation

struct DockerSystemInfo: Codable {
    let containers: Int?
    let containersRunning: Int?
    let containersPaused: Int?
    let containersStopped: Int?
    let images: Int?
    let serverVersion: String?
    let operatingSystem: String?
    let osType: String?
    let architecture: String?
    let memTotal: Int?
    let ncpu: Int?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case containers = "Containers"
        case containersRunning = "ContainersRunning"
        case containersPaused = "ContainersPaused"
        case containersStopped = "ContainersStopped"
        case images = "Images"
        case serverVersion = "ServerVersion"
        case operatingSystem = "OperatingSystem"
        case osType = "OsType"
        case architecture = "Architecture"
        case memTotal = "MemTotal"
        case ncpu = "NCPU"
        case name = "Name"
    }

    var memTotalFormatted: String {
        guard let mem = memTotal else { return "?" }
        return ByteCountFormatter.string(fromByteCount: Int64(mem), countStyle: .memory)
    }
}

struct DockerVersion: Codable {
    let version: String?
    let apiVersion: String?
    let goVersion: String?
    let os: String?
    let arch: String?

    enum CodingKeys: String, CodingKey {
        case version = "Version"
        case apiVersion = "ApiVersion"
        case goVersion = "GoVersion"
        case os = "Os"
        case arch = "Arch"
    }
}
