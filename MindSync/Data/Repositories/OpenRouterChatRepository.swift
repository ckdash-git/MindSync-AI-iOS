import Foundation

final class OpenRouterChatRepository: ChatRepositoryProtocol {

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
                    let apiKey = try apiKeyRepository.getKey()
                    let dtoMessages = buildMessages(from: session, newMessage: message)
                    let requestBody = OpenRouterChatRequestDTO(
                        model: model.id,
                        messages: dtoMessages,
                        stream: true,
                        maxTokens: AppConstants.API.defaultMaxTokens
                    )
                    let endpoint = OpenRouterChatEndpoint(apiKey: apiKey, requestBody: requestBody)
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
                    logError("OpenRouter stream error: \(error.localizedDescription)")
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

    private func buildMessages(from session: ChatSession, newMessage: ChatMessage) -> [OpenRouterChatRequestDTO.Message] {
        let history = Array(
            session.messages
                .suffix(AppConstants.Chat.maxHistoryCount)
                .filter { !$0.isStreaming }
        )
        // Append the new message only if it isn't already part of the session history.
        let allMessages = history.contains(where: { $0.id == newMessage.id })
            ? history
            : history + [newMessage]
        return allMessages.map { OpenRouterChatRequestDTO.Message(role: $0.role.rawValue, content: $0.content) }
    }
}
