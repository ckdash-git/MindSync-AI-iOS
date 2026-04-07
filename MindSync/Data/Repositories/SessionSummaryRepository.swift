import Foundation

final class SessionSummaryRepository: SessionSummaryRepositoryProtocol {

    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func summarize(messages: [ChatMessage]) async throws -> String {
        let dtoMessages = messages
            .filter { !$0.isStreaming }
            .map { SessionSummaryRequestDTO.Message(role: $0.role.rawValue, content: $0.content) }
        let requestBody = SessionSummaryRequestDTO(messages: dtoMessages)
        let endpoint = SessionSummaryEndpoint(requestBody: requestBody)
        let response = try await networkManager.request(endpoint, responseType: SessionSummaryResponseDTO.self)
        return response.summary
    }
}
