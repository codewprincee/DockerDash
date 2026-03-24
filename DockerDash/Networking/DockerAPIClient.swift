import Foundation

actor DockerAPIClient {
    static let shared = DockerAPIClient()

    private let socketPath = AppConstants.dockerSocketPath
    private let apiVersion = AppConstants.dockerAPIVersion
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - Connection Check

    func ping() async throws -> Bool {
        let data = try await curlGet("/_ping")
        return String(data: data, encoding: .utf8) == "OK"
    }

    // MARK: - GET

    func get<T: Decodable>(_ path: String) async throws -> T {
        let data = try await curlGet("/\(apiVersion)\(path)")
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw DockerAPIError.decodingError(error)
        }
    }

    // MARK: - POST (with response)

    func post<T: Decodable>(_ path: String, body: Data? = nil) async throws -> T {
        let data = try await curlPost("/\(apiVersion)\(path)", body: body)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw DockerAPIError.decodingError(error)
        }
    }

    // MARK: - POST (no content — 204)

    func postNoContent(_ path: String) async throws {
        _ = try await curlPost("/\(apiVersion)\(path)", body: nil)
    }

    // MARK: - DELETE

    func delete(_ path: String) async throws {
        _ = try await curlDelete("/\(apiVersion)\(path)")
    }

    // MARK: - GET Raw String (for logs)

    func getRawString(_ path: String) async throws -> String {
        let data = try await curlGet("/\(apiVersion)\(path)")
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - curl Transport

    private func curlGet(_ path: String) async throws -> Data {
        try await curlRequest(method: "GET", path: path)
    }

    private func curlPost(_ path: String, body: Data?) async throws -> Data {
        try await curlRequest(method: "POST", path: path, body: body)
    }

    private func curlDelete(_ path: String) async throws -> Data {
        try await curlRequest(method: "DELETE", path: path)
    }

    private func curlRequest(method: String, path: String, body: Data? = nil) async throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")

        var args = [
            "--unix-socket", socketPath,
            "-s", "-S",  // silent but show errors
            "-X", method,
            "http://localhost\(path)",
        ]

        if let body {
            args.append(contentsOf: ["-H", "Content-Type: application/json", "-d", String(data: body, encoding: .utf8) ?? ""])
        }

        process.arguments = args

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw DockerAPIError.connectionRefused
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMsg = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            if errorMsg.contains("connect") { throw DockerAPIError.connectionRefused }
            throw DockerAPIError.serverError(Int(process.terminationStatus), errorMsg)
        }

        return data
    }
}
