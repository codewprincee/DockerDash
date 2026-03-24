import Foundation

struct DockerVolume: Codable, Identifiable, Hashable {
    let name: String
    let driver: String
    let mountpoint: String
    let createdAt: String?
    let scope: String?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case driver = "Driver"
        case mountpoint = "Mountpoint"
        case createdAt = "CreatedAt"
        case scope = "Scope"
    }
}

struct VolumesResponse: Codable {
    let volumes: [DockerVolume]?

    enum CodingKeys: String, CodingKey {
        case volumes = "Volumes"
    }
}
