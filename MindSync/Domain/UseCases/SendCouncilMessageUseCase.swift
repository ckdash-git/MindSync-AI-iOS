import Foundation

protocol SendCouncilMessageUseCaseProtocol {
    func stream(content: String, model: AIModel) -> AsyncThrowingStream<String, Error>
}

final class SendCouncilMessageUseCase: SendCouncilMessageUseCaseProtocol {

    private let chatRepository: ChatRepositoryProtocol

    init(chatRepository: ChatRepositoryProtocol) {
        self.chatRepository = chatRepository
    }

    func stream(content: String, model: AIModel) -> AsyncThrowingStream<String, Error> {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return AsyncThrowingStream {
                $0.finish(throwing: AppError.custom(message: "Message cannot be empty."))
            }
        }

        guard content.count <= AppConstants.Chat.maxMessageLength else {
            return AsyncThrowingStream {
                $0.finish(throwing: AppError.custom(message: "Message is too long."))
            }
        }

        let session = ChatSession(selectedModel: model)
        let userMessage = ChatMessage(role: .user, content: content)
        return chatRepository.streamMessage(userMessage, session: session, model: model)
    }
}
