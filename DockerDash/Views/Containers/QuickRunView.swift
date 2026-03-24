import SwiftUI

struct QuickRunView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var imageName = ""
    @State private var containerName = ""
    @State private var ports: [PortEntry] = [PortEntry()]
    @State private var envVars: [EnvEntry] = [EnvEntry()]
    @State private var volumes: [VolumeEntry] = [VolumeEntry()]
    @State private var detached = true
    @State private var removeOnStop = false
    @State private var isRunning = false
    @State private var error: String?
    @State private var success: String?

    // Popular images
    private let popularImages = [
        "postgres:16", "redis:7-alpine", "mongo:7", "mysql:8",
        "nginx:latest", "node:20-alpine", "python:3.12-slim",
        "rabbitmq:management", "elasticsearch:8.15.0", "ubuntu:22.04"
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(.green)
                Text("Quick Run Container").font(.title3.bold())
                Spacer()
                Button("Cancel") { dismiss() }.buttonStyle(.plain).foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Image
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image").font(.caption.bold()).foregroundStyle(.secondary)
                        HStack {
                            TextField("e.g. postgres:16", text: $imageName).textFieldStyle(.roundedBorder)
                            Menu("Popular") {
                                ForEach(popularImages, id: \.self) { img in
                                    Button(img) { imageName = img }
                                }
                            }
                            .frame(width: 80)
                        }
                    }

                    // Container name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Container Name (optional)").font(.caption.bold()).foregroundStyle(.secondary)
                        TextField("e.g. my-postgres", text: $containerName).textFieldStyle(.roundedBorder)
                    }

                    // Ports
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Port Mappings").font(.caption.bold()).foregroundStyle(.secondary)
                            Spacer()
                            Button(action: { ports.append(PortEntry()) }) {
                                Image(systemName: "plus.circle").font(.caption)
                            }.buttonStyle(.plain)
                        }
                        ForEach($ports) { $port in
                            HStack {
                                TextField("Host", text: $port.host).textFieldStyle(.roundedBorder).frame(width: 80)
                                Text(":").foregroundStyle(.secondary)
                                TextField("Container", text: $port.container).textFieldStyle(.roundedBorder).frame(width: 80)
                                Button(action: { ports.removeAll { $0.id == port.id } }) {
                                    Image(systemName: "minus.circle").foregroundStyle(.red)
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    // Environment variables
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Environment Variables").font(.caption.bold()).foregroundStyle(.secondary)
                            Spacer()
                            Button(action: { envVars.append(EnvEntry()) }) {
                                Image(systemName: "plus.circle").font(.caption)
                            }.buttonStyle(.plain)
                        }
                        ForEach($envVars) { $env in
                            HStack {
                                TextField("KEY", text: $env.key).textFieldStyle(.roundedBorder).frame(width: 150)
                                Text("=").foregroundStyle(.secondary)
                                TextField("value", text: $env.value).textFieldStyle(.roundedBorder)
                                Button(action: { envVars.removeAll { $0.id == env.id } }) {
                                    Image(systemName: "minus.circle").foregroundStyle(.red)
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    // Options
                    HStack {
                        Toggle("Detached", isOn: $detached).toggleStyle(.switch).controlSize(.small)
                        Toggle("Remove on stop", isOn: $removeOnStop).toggleStyle(.switch).controlSize(.small)
                    }

                    // Generated command preview
                    GroupBox("Command Preview") {
                        Text(generatedCommand)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let error { Text(error).font(.caption).foregroundStyle(.red) }
                    if let success { Text(success).font(.caption).foregroundStyle(.green) }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button(action: { Task { await runContainer() } }) {
                    if isRunning {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Run Container", systemImage: "play.fill")
                    }
                }
                .buttonStyle(.borderedProminent).tint(.green).controlSize(.large)
                .disabled(imageName.isEmpty || isRunning)
            }
            .padding()
        }
        .frame(width: 560, height: 650)
    }

    private var generatedCommand: String {
        var cmd = "docker run"
        if detached { cmd += " -d" }
        if removeOnStop { cmd += " --rm" }
        if !containerName.isEmpty { cmd += " --name \(containerName)" }
        for port in ports where !port.host.isEmpty && !port.container.isEmpty {
            cmd += " -p \(port.host):\(port.container)"
        }
        for env in envVars where !env.key.isEmpty {
            cmd += " -e \(env.key)=\(env.value)"
        }
        cmd += " \(imageName)"
        return cmd
    }

    private func runContainer() async {
        isRunning = true
        error = nil
        success = nil

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")

        var args = ["docker", "run"]
        if detached { args.append("-d") }
        if removeOnStop { args.append("--rm") }
        if !containerName.isEmpty { args.append(contentsOf: ["--name", containerName]) }
        for port in ports where !port.host.isEmpty && !port.container.isEmpty {
            args.append(contentsOf: ["-p", "\(port.host):\(port.container)"])
        }
        for env in envVars where !env.key.isEmpty {
            args.append(contentsOf: ["-e", "\(env.key)=\(env.value)"])
        }
        args.append(imageName)

        process.arguments = args
        let pipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                success = "✓ Container started: \(output.prefix(12))"
            } else {
                let errOutput = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                self.error = errOutput
            }
        } catch {
            self.error = error.localizedDescription
        }
        isRunning = false
    }
}

struct PortEntry: Identifiable {
    let id = UUID()
    var host = ""
    var container = ""
}

struct EnvEntry: Identifiable {
    let id = UUID()
    var key = ""
    var value = ""
}

struct VolumeEntry: Identifiable {
    let id = UUID()
    var hostPath = ""
    var containerPath = ""
}
