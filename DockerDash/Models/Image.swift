import Foundation

struct DockerImage: Codable, Identifiable, Hashable {
    let id: String
    let repoTags: [String]?
    let created: Int
    let size: Int
    let virtualSize: Int?
    let containers: Int?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case repoTags = "RepoTags"
        case created = "Created"
        case size = "Size"
        case virtualSize = "VirtualSize"
        case containers = "Containers"
    }

    var displayName: String { repoTags?.first ?? String(id.prefix(12)) }
    var shortId: String { String(id.replacingOccurrences(of: "sha256:", with: "").prefix(12)) }
    var createdDate: Date { Date(timeIntervalSince1970: TimeInterval(created)) }
    var sizeFormatted: String { ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file) }

    static func == (lhs: DockerImage, rhs: DockerImage) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
