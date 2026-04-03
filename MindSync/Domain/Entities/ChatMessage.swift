import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let role: MessageRole
    var content: String
    let provider: AIProvider?
    let modelID: String?
    let timestamp: Date
    var isStreaming: Bool

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        provider: AIProvider? = nil,
        modelID: String? = nil,
        timestamp: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.provider = provider
        self.modelID = modelID
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
}

struct ChatSession: Identifiable, Codable, Sendable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date
    var selectedModel: AIModel

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        selectedModel: AIModel = .gpt4o
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.selectedModel = selectedModel
    }
}
