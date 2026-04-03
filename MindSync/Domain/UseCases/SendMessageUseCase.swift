import Foundation

protocol SendMessageUseCaseProtocol {
    func execute(
        content: String,
        session: ChatSession,
        model: AIModel
    ) -> AsyncThrowingStream<String, Error>
}

final class SendMessageUseCase: SendMessageUseCaseProtocol {

    private let chatRepository: ChatRepositoryProtocol

    init(chatRepository: ChatRepositoryProtocol) {
        self.chatRepository = chatRepository
    }

    func execute(
        content: String,
        session: ChatSession,
        model: AIModel
    ) -> AsyncThrowingStream<String, Error> {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: AppError.custom(message: "Message cannot be empty."))
            }
        }

        guard content.count <= AppConstants.Chat.maxMessageLength else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: AppError.custom(message: "Message is too long."))
            }
        }

        let userMessage = ChatMessage(role: .user, content: content)
        return chatRepository.streamMessage(userMessage, session: session, model: model)
    }
}
