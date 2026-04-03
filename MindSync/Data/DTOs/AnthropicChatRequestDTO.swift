import Foundation

struct AnthropicChatRequestDTO: Encodable {
    let model: String
    let messages: [Message]
    let maxTokens: Int
    let stream: Bool
    let system: String?

    init(
        model: String,
        messages: [Message],
        maxTokens: Int = AppConstants.API.anthropicDefaultMaxTokens,
        stream: Bool = true,
        system: String? = nil
    ) {
        self.model = model
        self.messages = messages
        self.maxTokens = maxTokens
        self.stream = stream
        self.system = system
    }

    struct Message: Encodable {
        let role: String   // "user" | "assistant" only — system is top-level
        let content: String
    }
}
