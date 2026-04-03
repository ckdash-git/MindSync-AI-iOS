import Foundation

/// Temporary stub repository.
/// Replace with a real implementation in the Chat feature module.
final class StubChatRepository: ChatRepositoryProtocol {

    private let networkManager: NetworkManagerProtocol
    private let apiKeyRepository: APIKeyRepositoryProtocol

    init(networkManager: NetworkManagerProtocol, apiKeyRepository: APIKeyRepositoryProtocol) {
        self.networkManager = networkManager
        self.apiKeyRepository = apiKeyRepository
    }

    func sendMessage(
        _ message: ChatMessage,
        session: ChatSession,
        model: AIModel
    ) async throws -> ChatMessage {
        throw AppError.custom(message: "Chat integration not yet implemented.")
    }

    func streamMessage(
        _ message: ChatMessage,
        session: ChatSession,
        model: AIModel
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: AppError.custom(message: "Chat integration not yet implemented."))
        }
    }

    func saveSession(_ session: ChatSession) async throws {
        logWarning("StubChatRepository: saveSession called — no-op.")
    }

    func loadSessions() async throws -> [ChatSession] {
        return []
    }

    func deleteSession(_ sessionID: UUID) async throws {
        logWarning("StubChatRepository: deleteSession called — no-op.")
    }
}
