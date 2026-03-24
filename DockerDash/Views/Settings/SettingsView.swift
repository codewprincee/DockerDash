import SwiftUI

struct SettingsView: View {
    @State private var systemService = SystemService()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let ver = systemService.version {
                    GroupBox("Docker Info") {
                        VStack(alignment: .leading, spacing: 6) {
                            row("Version", ver.version ?? "?")
                            row("API Version", ver.apiVersion ?? "?")
                            row("Go Version", ver.goVersion ?? "?")
                            row("OS/Arch", "\(ver.os ?? "?")/\(ver.arch ?? "?")")
                        }.padding(.vertical, 4)
                    }
                }
                GroupBox("About") {
                    VStack(alignment: .leading, spacing: 6) {
                        row("DockerDash", "v1.0.0")
                        row("Source", "github.com/codewprincee/DockerDash")
                        row("License", "MIT")
                    }.padding(.vertical, 4)
                }
            }.padding()
        }
        .navigationTitle("Settings")
        .task { await systemService.fetchInfo() }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack { Text(label).font(.caption).foregroundStyle(.secondary); Spacer(); Text(value).font(.caption.bold()) }
    }
}
