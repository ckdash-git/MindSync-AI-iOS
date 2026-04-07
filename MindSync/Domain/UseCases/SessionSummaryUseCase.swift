import Foundation

protocol SessionSummaryUseCaseProtocol {
    func summarize(session: ChatSession) async throws -> String
}

final class SessionSummaryUseCase: SessionSummaryUseCaseProtocol {

    private let summaryRepository: SessionSummaryRepositoryProtocol

    init(summaryRepository: SessionSummaryRepositoryProtocol) {
        self.summaryRepository = summaryRepository
    }

    func summarize(session: ChatSession) async throws -> String {
        let messages = session.messages.filter { $0.role != .system && !$0.isStreaming }
        guard !messages.isEmpty else {
            throw AppError.custom(message: "No messages to summarize.")
        }
        return try await summaryRepository.summarize(messages: messages)
    }
}
