import Foundation

struct DockerNetwork: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let driver: String
    let scope: String
    let internal_: Bool?
    let containers: [String: NetworkContainer]?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case driver = "Driver"
        case scope = "Scope"
        case internal_ = "Internal"
        case containers = "Containers"
    }

    var containerCount: Int { containers?.count ?? 0 }

    static func == (lhs: DockerNetwork, rhs: DockerNetwork) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct NetworkContainer: Codable, Hashable {
    let name: String?
    let endpointId: String?
    let macAddress: String?
    let ipv4Address: String?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case endpointId = "EndpointID"
        case macAddress = "MacAddress"
        case ipv4Address = "IPv4Address"
    }
}
