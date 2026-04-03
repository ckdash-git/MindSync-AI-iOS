import Foundation

protocol ChatRepositoryProtocol {
    func sendMessage(
        _ message: ChatMessage,
        session: ChatSession,
        model: AIModel
    ) async throws -> ChatMessage

    func streamMessage(
        _ message: ChatMessage,
        session: ChatSession,
        model: AIModel
    ) -> AsyncThrowingStream<String, Error>

    func saveSession(_ session: ChatSession) async throws
    func loadSessions() async throws -> [ChatSession]
    func deleteSession(_ sessionID: UUID) async throws
}
