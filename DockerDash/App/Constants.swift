import Foundation

enum AppConstants {
    static let dockerSocketPath = "/var/run/docker.sock"
    static let dockerAPIVersion = "v1.44"
    static let containerPollInterval: TimeInterval = 3
    static let statsPollInterval: TimeInterval = 2
    static let imagePollInterval: TimeInterval = 30
}
