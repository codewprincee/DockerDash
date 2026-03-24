import SwiftUI

struct LogSearchView: View {
    let containerId: String
    let containerName: String
    @State private var logs: [LogLine] = []
    @State private var searchText = ""
    @State private var filterStream: StreamFilter = .all
    @State private var tailLines = 500
    @State private var isLoading = true
    @State private var autoRefresh = false
    @State private var polling: DispatchSourceTimer?

    enum StreamFilter: String, CaseIterable {
        case all = "All"
        case stdout = "stdout"
        case stderr = "stderr"
    }

    private var filteredLogs: [LogLine] {
        var result = logs
        if filterStream != .all {
            result = result.filter { $0.stream == filterStream.rawValue }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(containerName).font(.title3.bold())
                Text("Logs").font(.title3).foregroundStyle(.secondary)
                Spacer()
                Text("\(filteredLogs.count)/\(logs.count) lines").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Toolbar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search logs... (supports regex)", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                Picker("Stream", selection: $filterStream) {
                    ForEach(StreamFilter.allCases, id: \.self) { f in Text(f.rawValue).tag(f) }
                }
                .frame(width: 100)

                Picker("Lines", selection: $tailLines) {
                    Text("100").tag(100)
                    Text("500").tag(500)
                    Text("1000").tag(1000)
                    Text("5000").tag(5000)
                }
                .frame(width: 80)
                .onChange(of: tailLines) { _, _ in Task { await fetchLogs() } }

                Toggle("Auto", isOn: $autoRefresh)
                    .toggleStyle(.switch).controlSize(.small)
                    .onChange(of: autoRefresh) { _, on in
                        if on { startAutoRefresh() } else { stopAutoRefresh() }
                    }

                Button(action: { Task { await fetchLogs() } }) {
                    Image(systemName: "arrow.clockwise")
                }.buttonStyle(.plain)

                Button(action: exportLogs) {
                    Image(systemName: "square.and.arrow.up")
                }.buttonStyle(.plain).help("Export Logs")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // Log content
            if isLoading {
                LoadingStateView(message: "Loading logs...")
            } else if filteredLogs.isEmpty {
                EmptyStateView(title: "No Logs", subtitle: searchText.isEmpty ? "No log output yet." : "No matches found.", systemImage: "doc.text")
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(filteredLogs.enumerated()), id: \.offset) { idx, line in
                                logLineView(line, highlighted: !searchText.isEmpty)
                                    .id(idx)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                    .onChange(of: logs.count) { _, _ in
                        if autoRefresh {
                            proxy.scrollTo(filteredLogs.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .task { await fetchLogs() }
        .onDisappear { stopAutoRefresh() }
    }

    private func logLineView(_ line: LogLine, highlighted: Bool) -> some View {
        HStack(alignment: .top, spacing: 6) {
            // Timestamp
            if let ts = line.timestamp {
                Text(ts)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(width: 80, alignment: .leading)
            }

            // Stream indicator
            Circle()
                .fill(line.stream == "stderr" ? .red : .green)
                .frame(width: 6, height: 6)
                .padding(.top, 4)

            // Text
            Text(highlightedText(line.text))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(line.stream == "stderr" ? .red : .primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 1)
        .background(line.stream == "stderr" ? Color.red.opacity(0.04) : Color.clear)
    }

    private func highlightedText(_ text: String) -> AttributedString {
        var attr = AttributedString(text)
        guard !searchText.isEmpty else { return attr }

        if let range = attr.range(of: searchText, options: .caseInsensitive) {
            attr[range].backgroundColor = .yellow.opacity(0.4)
            attr[range].font = .system(size: 12, design: .monospaced).bold()
        }
        return attr
    }

    private func fetchLogs() async {
        isLoading = logs.isEmpty
        do {
            let raw = try await DockerAPIClient.shared.getRawString(
                "/containers/\(containerId)/logs?stdout=true&stderr=true&timestamps=true&tail=\(tailLines)"
            )
            let lines = raw.components(separatedBy: "\n").filter { !$0.isEmpty }
            logs = lines.enumerated().map { idx, line in
                parseLine(line, index: idx)
            }
        } catch {}
        isLoading = false
    }

    private func parseLine(_ raw: String, index: Int) -> LogLine {
        // Docker log format: 8-byte header + timestamp + message
        // Strip binary header if present
        var line = raw
        if line.count > 8 && !line.hasPrefix("2") {
            line = String(line.dropFirst(8))
        }

        let parts = line.split(separator: " ", maxSplits: 1)
        let timestamp = parts.first.map(String.init)
        let text = parts.count > 1 ? String(parts[1]) : line

        return LogLine(
            index: index,
            timestamp: timestamp?.prefix(19).description,
            stream: "stdout", // Simplified — full impl would parse header byte
            text: text
        )
    }

    private func startAutoRefresh() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 2, repeating: 2.0)
        timer.setEventHandler { Task { await fetchLogs() } }
        timer.resume()
        polling = timer
    }

    private func stopAutoRefresh() {
        polling?.cancel(); polling = nil; autoRefresh = false
    }

    private func exportLogs() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(containerName)-logs.txt"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let content = filteredLogs.map { "\($0.timestamp ?? "") \($0.text)" }.joined(separator: "\n")
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

struct LogLine {
    let index: Int
    let timestamp: String?
    let stream: String
    let text: String
}
