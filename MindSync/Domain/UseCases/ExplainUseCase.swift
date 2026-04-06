import Foundation

protocol ExplainUseCaseProtocol {
    func stream(message: String, model: String) -> AsyncThrowingStream<String, Error>
}

final class ExplainUseCase: ExplainUseCaseProtocol {

    private let explainRepository: ExplainRepositoryProtocol

    init(explainRepository: ExplainRepositoryProtocol) {
        self.explainRepository = explainRepository
    }

    func stream(message: String, model: String) -> AsyncThrowingStream<String, Error> {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return AsyncThrowingStream { $0.finish(throwing: AppError.custom(message: "Message cannot be empty.")) }
        }
        guard trimmed.count <= AppConstants.Chat.maxMessageLength else {
            return AsyncThrowingStream { $0.finish(throwing: AppError.custom(message: "Message exceeds maximum length.")) }
        }
        return explainRepository.stream(message: trimmed, model: model)
    }
}
