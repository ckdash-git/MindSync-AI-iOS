import Foundation

final class SessionSummaryRepository: SessionSummaryRepositoryProtocol {

    private let networkManager: NetworkManagerProtocol
    private let apiKeyRepository: APIKeyRepositoryProtocol

    init(
        networkManager: NetworkManagerProtocol,
        apiKeyRepository: APIKeyRepositoryProtocol
    ) {
        self.networkManager = networkManager
        self.apiKeyRepository = apiKeyRepository
    }

    func summarize(messages: [ChatMessage]) async throws -> String {
        let apiKey = try apiKeyRepository.getKey()
        let dtoMessages = messages
            .filter { !$0.isStreaming }
            .map { SessionSummaryRequestDTO.Message(role: $0.role.rawValue, content: $0.content) }
        let requestBody = SessionSummaryRequestDTO(messages: dtoMessages)
        let endpoint = SessionSummaryEndpoint(apiKey: apiKey, requestBody: requestBody)
        let response = try await networkManager.request(endpoint, responseType: SessionSummaryResponseDTO.self)
        return response.summary
    }
}
