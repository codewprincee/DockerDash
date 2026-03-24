import SwiftUI
import Charts

struct ResourceMonitorView: View {
    let containerId: String
    let containerName: String
    @State private var cpuHistory: [StatPoint] = []
    @State private var memHistory: [StatPoint] = []
    @State private var netRxHistory: [StatPoint] = []
    @State private var netTxHistory: [StatPoint] = []
    @State private var currentCPU: Double = 0
    @State private var currentMem: Double = 0
    @State private var memLimit: Double = 0
    @State private var isStreaming = false
    @State private var polling: DispatchSourceTimer?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ContainerStatusBadge(state: "running")
                Text(containerName).font(.title3.bold())
                Spacer()
                Circle().fill(isStreaming ? .green : .red).frame(width: 8, height: 8)
                Text(isStreaming ? "Live" : "Stopped").font(.caption).foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Current stats
                    HStack(spacing: 20) {
                        statCard("CPU", value: String(format: "%.1f%%", currentCPU), color: .blue)
                        statCard("Memory", value: String(format: "%.0f MB", currentMem), color: .purple)
                        statCard("Mem Limit", value: String(format: "%.0f MB", memLimit), color: .orange)
                    }

                    // CPU chart
                    GroupBox("CPU Usage (%)") {
                        Chart(cpuHistory) { point in
                            LineMark(x: .value("Time", point.time), y: .value("CPU", point.value))
                                .foregroundStyle(.blue)
                            AreaMark(x: .value("Time", point.time), y: .value("CPU", point.value))
                                .foregroundStyle(.blue.opacity(0.1))
                        }
                        .chartYScale(domain: 0...max(100, (cpuHistory.map(\.value).max() ?? 0) * 1.2))
                        .frame(height: 150)
                    }

                    // Memory chart
                    GroupBox("Memory Usage (MB)") {
                        Chart(memHistory) { point in
                            LineMark(x: .value("Time", point.time), y: .value("Memory", point.value))
                                .foregroundStyle(.purple)
                            AreaMark(x: .value("Time", point.time), y: .value("Memory", point.value))
                                .foregroundStyle(.purple.opacity(0.1))
                        }
                        .chartYScale(domain: 0...max(memLimit, (memHistory.map(\.value).max() ?? 0) * 1.2))
                        .frame(height: 150)
                    }

                    // Network I/O
                    GroupBox("Network I/O (KB/s)") {
                        Chart {
                            ForEach(netRxHistory) { point in
                                LineMark(x: .value("Time", point.time), y: .value("RX", point.value))
                                    .foregroundStyle(.green)
                            }
                            ForEach(netTxHistory) { point in
                                LineMark(x: .value("Time", point.time), y: .value("TX", point.value))
                                    .foregroundStyle(.orange)
                            }
                        }
                        .frame(height: 120)

                        HStack {
                            Circle().fill(.green).frame(width: 8, height: 8); Text("RX").font(.caption2)
                            Circle().fill(.orange).frame(width: 8, height: 8); Text("TX").font(.caption2)
                            Spacer()
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
    }

    private func statCard(_ title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold().monospacedDigit())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private func startPolling() {
        isStreaming = true
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 2.0)
        timer.setEventHandler { Task { await fetchStats() } }
        timer.resume()
        polling = timer
    }

    private func stopPolling() {
        polling?.cancel()
        polling = nil
        isStreaming = false
    }

    private func fetchStats() async {
        do {
            let data = try await DockerAPIClient.shared.getRawString("/containers/\(containerId)/stats?stream=false")
            guard let jsonData = data.data(using: .utf8) else { return }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let stats = try decoder.decode(ContainerStatsResponse.self, from: jsonData)

            let now = Date()

            // CPU calculation
            let cpuDelta = Double(stats.cpuStats.cpuUsage.totalUsage - stats.precpuStats.cpuUsage.totalUsage)
            let sysDelta = Double(stats.cpuStats.systemCpuUsage - stats.precpuStats.systemCpuUsage)
            let cpuCount = Double(stats.cpuStats.onlineCpus ?? 1)
            let cpuPercent = sysDelta > 0 ? (cpuDelta / sysDelta) * cpuCount * 100.0 : 0

            // Memory
            let memUsageMB = Double(stats.memoryStats.usage) / 1_048_576
            let memLimitMB = Double(stats.memoryStats.limit) / 1_048_576

            await MainActor.run {
                currentCPU = cpuPercent
                currentMem = memUsageMB
                memLimit = memLimitMB

                cpuHistory.append(StatPoint(time: now, value: cpuPercent))
                memHistory.append(StatPoint(time: now, value: memUsageMB))

                // Keep last 60 data points (2 min at 2s intervals)
                if cpuHistory.count > 60 { cpuHistory.removeFirst() }
                if memHistory.count > 60 { memHistory.removeFirst() }
                if netRxHistory.count > 60 { netRxHistory.removeFirst() }
                if netTxHistory.count > 60 { netTxHistory.removeFirst() }
            }
        } catch {}
    }
}

struct StatPoint: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double
}

// MARK: - Docker Stats Response Models

struct ContainerStatsResponse: Codable {
    let cpuStats: CPUStats
    let precpuStats: CPUStats
    let memoryStats: MemoryStatsResponse

    struct CPUStats: Codable {
        let cpuUsage: CPUUsage
        let systemCpuUsage: Int
        let onlineCpus: Int?

        struct CPUUsage: Codable {
            let totalUsage: Int
        }
    }

    struct MemoryStatsResponse: Codable {
        let usage: Int
        let limit: Int
    }
}
