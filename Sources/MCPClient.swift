// ============================================================================
// MCPClient.swift - MCP server connection and tool execution
// Part of apfel - spawns MCP servers and manages tool calling
// ============================================================================

import Foundation
import ApfelCore

/// A connection to a single MCP server process (stdio transport).
final class MCPConnection: @unchecked Sendable {
    let path: String
    private(set) var tools: [OpenAITool]

    private let process: Process
    private let stdinPipe: Pipe
    private let stdoutPipe: Pipe
    private let lock = NSLock()
    private var nextId = 1

    init(path: String) async throws {
        self.path = path

        let proc = Process()
        let stdinP = Pipe()
        let stdoutP = Pipe()

        if path.hasSuffix(".py") {
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            proc.arguments = ["python3", path]
        } else {
            proc.executableURL = URL(fileURLWithPath: path)
        }
        proc.standardInput = stdinP
        proc.standardOutput = stdoutP
        proc.standardError = FileHandle.nullDevice

        self.process = proc
        self.stdinPipe = stdinP
        self.stdoutPipe = stdoutP
        self.tools = [] // placeholder, filled below

        try proc.run()

        // Initialize handshake
        let initResp = try sendAndReceive(MCPProtocol.initializeRequest(id: allocId()))
        let _ = try MCPProtocol.parseInitializeResponse(initResp)
        send(MCPProtocol.initializedNotification())

        // Discover tools
        let toolsResp = try sendAndReceive(MCPProtocol.toolsListRequest(id: allocId()))
        self.tools = try MCPProtocol.parseToolsListResponse(toolsResp)
    }

    func callTool(name: String, arguments: String) throws -> String {
        let resp = try sendAndReceive(MCPProtocol.toolsCallRequest(id: allocId(), name: name, arguments: arguments))
        let result = try MCPProtocol.parseToolCallResponse(resp)
        return result.text
    }

    func shutdown() {
        process.terminate()
    }

    deinit {
        if process.isRunning { process.terminate() }
    }

    // MARK: - Private

    private func allocId() -> Int {
        lock.lock()
        defer { lock.unlock() }
        let id = nextId
        nextId += 1
        return id
    }

    private func send(_ message: String) {
        let data = (message + "\n").data(using: .utf8)!
        stdinPipe.fileHandleForWriting.write(data)
    }

    private func sendAndReceive(_ message: String) throws -> String {
        send(message)
        // Read one line from stdout
        let handle = stdoutPipe.fileHandleForReading
        var buffer = Data()
        while true {
            let byte = handle.readData(ofLength: 1)
            if byte.isEmpty { throw MCPError.processError("MCP server closed unexpectedly") }
            if byte[0] == UInt8(ascii: "\n") { break }
            buffer.append(byte)
        }
        guard let line = String(data: buffer, encoding: .utf8), !line.isEmpty else {
            throw MCPError.processError("Empty response from MCP server")
        }
        return line
    }
}

/// Manages multiple MCP server connections and routes tool calls.
actor MCPManager {
    private var connections: [MCPConnection] = []
    private var toolMap: [String: MCPConnection] = [:]

    init(paths: [String]) async throws {
        for path in paths {
            let absPath: String
            if path.hasPrefix("/") {
                absPath = path
            } else {
                absPath = FileManager.default.currentDirectoryPath + "/" + path
            }
            let conn = try await MCPConnection(path: absPath)
            connections.append(conn)
            for tool in conn.tools {
                toolMap[tool.function.name] = conn
            }
            printStderr("\(styled("mcp:", .cyan)) \(conn.path) - \(conn.tools.map(\.function.name).joined(separator: ", "))")
        }
    }

    func allTools() -> [OpenAITool] {
        connections.flatMap(\.tools)
    }

    func execute(name: String, arguments: String) throws -> String {
        guard let conn = toolMap[name] else {
            throw MCPError.toolNotFound("No MCP server provides tool '\(name)'")
        }
        return try conn.callTool(name: name, arguments: arguments)
    }

    func shutdown() {
        for conn in connections {
            conn.shutdown()
        }
    }
}
