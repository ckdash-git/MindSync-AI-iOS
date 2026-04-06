import Foundation

/// Parses Server-Sent Events (SSE) lines.
/// Handles both OpenAI-style `data: {...}` lines and raw token strings.
enum SSEParser {

    static func parse(line: String) -> String? {
        guard line.hasPrefix("data: ") else { return nil }

        let payload = String(line.dropFirst(6))

        guard payload != "[DONE]" else { return nil }

        return payload
    }

    /// Attempts to extract a text delta from a raw JSON string.
    static func extractToken(from jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        // OpenAI delta format
        if let choices = json["choices"] as? [[String: Any]],
           let delta = choices.first?["delta"] as? [String: Any],
           let content = delta["content"] as? String {
            return content
        }

        // Anthropic delta format
        if let delta = json["delta"] as? [String: Any],
           let text = delta["text"] as? String {
            return text
        }

        // Gemini format
        if let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return text
        }

        // Backend flat format: { "content": "..." } or { "delta": "..." }
        if let content = json["content"] as? String { return content }
        if let delta = json["delta"] as? String { return delta }

        return nil
    }
}
