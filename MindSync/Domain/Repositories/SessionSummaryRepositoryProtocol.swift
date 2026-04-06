import Foundation

protocol SessionSummaryRepositoryProtocol {
    func summarize(messages: [ChatMessage]) async throws -> String
}
