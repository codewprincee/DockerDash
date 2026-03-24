import Foundation

enum DockerAPIError: LocalizedError {
    case connectionRefused
    case socketNotFound
    case notFound(String)
    case conflict(String)
    case serverError(Int, String)
    case decodingError(Error)
    case networkError(Error)
    case timeout

    var errorDescription: String? {
        switch self {
        case .connectionRefused: return "Cannot connect to Docker. Is Docker Desktop running?"
        case .socketNotFound: return "Docker socket not found at /var/run/docker.sock"
        case .notFound(let msg): return "Not found: \(msg)"
        case .conflict(let msg): return "Conflict: \(msg)"
        case .serverError(let code, let msg): return "Docker error (\(code)): \(msg)"
        case .decodingError(let err): return "Failed to parse Docker response: \(err.localizedDescription)"
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .timeout: return "Request timed out"
        }
    }
}
