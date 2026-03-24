import Foundation

struct DockerContainer: Codable, Identifiable, Hashable {
    let id: String
    let names: [String]
    let image: String
    let imageId: String
    let command: String
    let created: Int
    let state: String
    let status: String
    let ports: [PortMapping]?
    let labels: [String: String]?
    let mounts: [Mount]?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case names = "Names"
        case image = "Image"
        case imageId = "ImageID"
        case command = "Command"
        case created = "Created"
        case state = "State"
        case status = "Status"
        case ports = "Ports"
        case labels = "Labels"
        case mounts = "Mounts"
    }

    var displayName: String {
        names.first?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? String(id.prefix(12))
    }

    var shortId: String { String(id.prefix(12)) }
    var isRunning: Bool { state == "running" }
    var isPaused: Bool { state == "paused" }
    var isStopped: Bool { state == "exited" || state == "dead" || state == "created" }

    var composeProject: String? { labels?["com.docker.compose.project"] }
    var composeService: String? { labels?["com.docker.compose.service"] }

    var createdDate: Date { Date(timeIntervalSince1970: TimeInterval(created)) }

    static func == (lhs: DockerContainer, rhs: DockerContainer) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct PortMapping: Codable, Hashable {
    let ip: String?
    let privatePort: Int
    let publicPort: Int?
    let type: String

    enum CodingKeys: String, CodingKey {
        case ip = "IP"
        case privatePort = "PrivatePort"
        case publicPort = "PublicPort"
        case type = "Type"
    }

    var displayString: String {
        if let pub = publicPort {
            return "\(ip ?? "0.0.0.0"):\(pub) → \(privatePort)/\(type)"
        }
        return "\(privatePort)/\(type)"
    }
}

struct Mount: Codable, Hashable {
    let type: String?
    let name: String?
    let source: String?
    let destination: String?
    let driver: String?
    let rw: Bool?

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case name = "Name"
        case source = "Source"
        case destination = "Destination"
        case driver = "Driver"
        case rw = "RW"
    }
}
