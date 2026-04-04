import Foundation

struct OpenRouterChatRequestDTO: Encodable {
    let model: String
    let messages: [Message]
    let stream: Bool
    let maxTokens: Int?

    init(model: String, messages: [Message], stream: Bool = true, maxTokens: Int? = nil) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.maxTokens = maxTokens
    }

    struct Message: Encodable {
        let role: String
        let content: String
    }
}
