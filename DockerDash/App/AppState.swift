import SwiftUI

@Observable
final class AppState {
    var selectedSection: SidebarSection = .dashboard
    var selectedContainerId: String?
    var showCommandPalette = false
    var showCleanupWizard = false
    var showQuickRun = false
    var isDockerConnected = false

    enum SidebarSection: String, CaseIterable, Identifiable {
        case dashboard, containers, images, volumes, networks, ports, compose, cleanup, settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .containers: return "Containers"
            case .images: return "Images"
            case .volumes: return "Volumes"
            case .networks: return "Networks"
            case .ports: return "Port Map"
            case .compose: return "Compose"
            case .cleanup: return "Cleanup"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .containers: return "shippingbox"
            case .images: return "photo.stack"
            case .volumes: return "externaldrive"
            case .networks: return "network"
            case .ports: return "arrow.left.arrow.right"
            case .compose: return "rectangle.3.group"
            case .cleanup: return "trash.circle"
            case .settings: return "gear"
            }
        }
    }
}
