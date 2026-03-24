import SwiftUI

struct CommandPaletteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var query = ""

    private let commands: [(icon: String, title: String, section: AppState.SidebarSection)] = [
        ("square.grid.2x2", "Dashboard", .dashboard),
        ("shippingbox", "Containers", .containers),
        ("photo.stack", "Images", .images),
        ("externaldrive", "Volumes", .volumes),
        ("network", "Networks", .networks),
        ("rectangle.3.group", "Compose", .compose),
        ("gear", "Settings", .settings),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Type a command...", text: $query).textFieldStyle(.plain).font(.title3)
                    .onSubmit { if let first = filtered.first { execute(first) } }
                Button("Esc") { dismiss() }.buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
                    .keyboardShortcut(.escape, modifiers: [])
            }.padding()
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(filtered, id: \.title) { cmd in
                        Button(action: { execute(cmd) }) {
                            HStack {
                                Image(systemName: cmd.icon).frame(width: 20).foregroundStyle(.secondary)
                                Text(cmd.title); Spacer()
                            }.padding(.horizontal).padding(.vertical, 8).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }.padding(.vertical, 4)
            }
        }.frame(width: 500, height: 350)
    }

    private var filtered: [(icon: String, title: String, section: AppState.SidebarSection)] {
        query.isEmpty ? commands : commands.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    private func execute(_ cmd: (icon: String, title: String, section: AppState.SidebarSection)) {
        appState.selectedSection = cmd.section; dismiss()
    }
}
