import Foundation

/// Routes chat operations to the correct provider repository based on the model's provider.
/// This is the single `ChatRepositoryProtocol` instance registered in the DI container.
final class ChatRepositoryRouter: ChatRepositoryProtocol {

    private let openAIRepository: ChatRepositoryProtocol
    private let anthropicRepository: ChatRepositoryProtocol
    private let geminiRepository: ChatRepositoryProtocol

    init(
        openAIRepository: ChatRepositoryProtocol,
        anthropicRepository: ChatRepositoryProtocol,
        geminiRepository: ChatRepositoryProtocol
    ) {
        self.openAIRepository = openAIRepository
        self.anthropicRepository = anthropicRepository
        self.geminiRepository = geminiRepository
    }

    func streamMessage(
        _ message: ChatMessage,
        session: ChatSession,
        model: AIModel
    ) -> AsyncThrowingStream<String, Error> {
        repository(for: model).streamMessage(message, session: session, model: model)
    }

    func sendMessage(
        _ message: ChatMessage,
        session: ChatSession,
        model: AIModel
    ) async throws -> ChatMessage {
        try await repository(for: model).sendMessage(message, session: session, model: model)
    }

    func saveSession(_ session: ChatSession) async throws {}
    func loadSessions() async throws -> [ChatSession] { [] }
    func deleteSession(_ sessionID: UUID) async throws {}

    // MARK: - Private

    private func repository(for model: AIModel) -> ChatRepositoryProtocol {
        switch model.provider {
        case .openAI:    return openAIRepository
        case .anthropic: return anthropicRepository
        case .gemini:    return geminiRepository
        }
    }
}
