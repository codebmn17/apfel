// MCPClientTests - TDD tests for MCP JSON-RPC protocol handling
// Tests the pure protocol logic (message formatting, parsing) without spawning processes

import Foundation
import ApfelCore

func runMCPClientTests() {

    // MARK: - JSON-RPC message formatting

    test("formatInitialize produces valid JSON-RPC") {
        let msg = MCPProtocol.initializeRequest(id: 1)
        let data = msg.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        try assertEqual(obj["jsonrpc"] as! String, "2.0")
        try assertEqual(obj["id"] as! Int, 1)
        try assertEqual(obj["method"] as! String, "initialize")
        let params = obj["params"] as! [String: Any]
        try assertEqual(params["protocolVersion"] as! String, "2025-06-18")
    }

    test("formatToolsList produces valid JSON-RPC") {
        let msg = MCPProtocol.toolsListRequest(id: 2)
        let data = msg.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        try assertEqual(obj["method"] as! String, "tools/list")
        try assertEqual(obj["id"] as! Int, 2)
    }

    test("formatToolsCall produces valid JSON-RPC") {
        let msg = MCPProtocol.toolsCallRequest(id: 3, name: "multiply", arguments: "{\"a\":247,\"b\":83}")
        let data = msg.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        try assertEqual(obj["method"] as! String, "tools/call")
        let params = obj["params"] as! [String: Any]
        try assertEqual(params["name"] as! String, "multiply")
        let args = params["arguments"] as! [String: Any]
        try assertEqual(args["a"] as! Int, 247)
    }

    test("formatNotificationInitialized has no id") {
        let msg = MCPProtocol.initializedNotification()
        let data = msg.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        try assertEqual(obj["method"] as! String, "notifications/initialized")
        try assertNil(obj["id"])
    }

    // MARK: - Response parsing

    test("parseInitializeResponse extracts server info") {
        let json = """
        {"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2025-06-18","capabilities":{"tools":{}},"serverInfo":{"name":"calc","version":"1.0"}}}
        """
        let info = try MCPProtocol.parseInitializeResponse(json)
        try assertEqual(info.name, "calc")
        try assertEqual(info.version, "1.0")
    }

    test("parseToolsListResponse extracts tool definitions") {
        let json = """
        {"jsonrpc":"2.0","id":2,"result":{"tools":[{"name":"add","description":"Add two numbers","inputSchema":{"type":"object","properties":{"a":{"type":"number"},"b":{"type":"number"}},"required":["a","b"]}}]}}
        """
        let tools = try MCPProtocol.parseToolsListResponse(json)
        try assertEqual(tools.count, 1)
        try assertEqual(tools[0].function.name, "add")
        try assertEqual(tools[0].function.description, "Add two numbers")
        try assertEqual(tools[0].type, "function")
    }

    test("parseToolsListResponse handles multiple tools") {
        let json = """
        {"jsonrpc":"2.0","id":2,"result":{"tools":[{"name":"add","description":"Add","inputSchema":{"type":"object","properties":{}}},{"name":"multiply","description":"Multiply","inputSchema":{"type":"object","properties":{}}}]}}
        """
        let tools = try MCPProtocol.parseToolsListResponse(json)
        try assertEqual(tools.count, 2)
        try assertEqual(tools[0].function.name, "add")
        try assertEqual(tools[1].function.name, "multiply")
    }

    test("parseToolCallResponse extracts text result") {
        let json = """
        {"jsonrpc":"2.0","id":3,"result":{"content":[{"type":"text","text":"20501"}],"isError":false}}
        """
        let result = try MCPProtocol.parseToolCallResponse(json)
        try assertEqual(result.text, "20501")
        try assertTrue(!result.isError)
    }

    test("parseToolCallResponse detects errors") {
        let json = """
        {"jsonrpc":"2.0","id":4,"result":{"content":[{"type":"text","text":"Error: division by zero"}],"isError":true}}
        """
        let result = try MCPProtocol.parseToolCallResponse(json)
        try assertEqual(result.text, "Error: division by zero")
        try assertTrue(result.isError)
    }

    test("parseToolCallResponse handles JSON-RPC error") {
        let json = """
        {"jsonrpc":"2.0","id":5,"error":{"code":-32602,"message":"Unknown tool: fake"}}
        """
        let result = try MCPProtocol.parseToolCallResponse(json)
        try assertTrue(result.isError)
        try assertTrue(result.text.contains("Unknown tool"))
    }

    // MARK: - Edge cases

    test("parseToolsListResponse handles empty tools array") {
        let json = """
        {"jsonrpc":"2.0","id":2,"result":{"tools":[]}}
        """
        let tools = try MCPProtocol.parseToolsListResponse(json)
        try assertEqual(tools.count, 0)
    }

    test("parseToolCallResponse handles missing isError (defaults to false)") {
        let json = """
        {"jsonrpc":"2.0","id":3,"result":{"content":[{"type":"text","text":"42"}]}}
        """
        let result = try MCPProtocol.parseToolCallResponse(json)
        try assertEqual(result.text, "42")
        try assertTrue(!result.isError)
    }

    test("tool schema converts to OpenAI format with parameters") {
        let json = """
        {"jsonrpc":"2.0","id":2,"result":{"tools":[{"name":"sqrt","description":"Square root","inputSchema":{"type":"object","properties":{"a":{"type":"number","description":"The number"}},"required":["a"]}}]}}
        """
        let tools = try MCPProtocol.parseToolsListResponse(json)
        try assertNotNil(tools[0].function.parameters)
    }
}
