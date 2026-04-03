import Foundation

final class AnthropicChatRepository: ChatRepositoryProtocol {

    private let networkManager: NetworkManagerProtocol
    private let apiKeyRepository: APIKeyRepositoryProtocol

    init(
        networkManager: NetworkManagerProtocol,
        apiKeyRepository: APIKeyRepositoryProtocol
    ) {
        self.networkManager = networkManager
        self.apiKeyRepository = apiKeyRepository
    }

    func streamMessage(
        _ message: ChatMessage,
        session: ChatSession,
        model: AIModel
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let apiKey = try apiKeyRepository.getKey(for: .anthropic)
                    let (systemPrompt, dtoMessages) = buildMessages(from: session, newMessage: message)
                    let requestBody = AnthropicChatRequestDTO(
                        model: model.id,
                        messages: dtoMessages,
                        maxTokens: AppConstants.API.anthropicDefaultMaxTokens,
                        stream: true,
                        system: systemPrompt
                    )
                    let endpoint = AnthropicChatEndpoint(apiKey: apiKey, requestBody: requestBody)
                    let rawStream = networkManager.stream(endpoint)

                    for try await jsonToken in rawStream {
                        if let delta = SSEParser.extractToken(from: jsonToken) {
                            continuation.yield(delta)
                        }
                    }
                    continuation.finish()

                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    logError("Anthropic stream error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func sendMessage(
        _ message: ChatMessage,
        session: ChatSession,
        model: AIModel
    ) async throws -> ChatMessage {
        throw AppError.custom(message: "Use streamMessage for real-time responses.")
    }

    func saveSession(_ session: ChatSession) async throws {}
    func loadSessions() async throws -> [ChatSession] { [] }
    func deleteSession(_ sessionID: UUID) async throws {}

    // MARK: - Private

    /// Returns (systemPrompt, messages).
    /// Anthropic requires system content at the top level — not inside the messages array.
    private func buildMessages(
        from session: ChatSession,
        newMessage: ChatMessage
    ) -> (systemPrompt: String?, messages: [AnthropicChatRequestDTO.Message]) {
        let history = Array(
            session.messages
                .suffix(AppConstants.Chat.maxHistoryCount)
                .filter { !$0.isStreaming }
        )
        let allMessages = history.contains(where: { $0.id == newMessage.id })
            ? history
            : history + [newMessage]

        let systemContent = allMessages
            .filter { $0.role == .system }
            .map(\.content)
            .joined(separator: "\n")

        let conversationMessages = allMessages
            .filter { $0.role != .system }
            .map { AnthropicChatRequestDTO.Message(role: $0.role.rawValue, content: $0.content) }

        return (systemContent.isEmpty ? nil : systemContent, conversationMessages)
    }
}
