import Foundation

final class BackendChatRepository: ChatRepositoryProtocol {

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
                    let requestBody = BackendChatRequestDTO(
                        message: message.content,
                        model: model.id
                    )
                    let endpoint = BackendChatEndpoint(apiKey: apiKey, requestBody: requestBody)
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
                    logError("Backend chat stream error: \(error.localizedDescription)")
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
}
