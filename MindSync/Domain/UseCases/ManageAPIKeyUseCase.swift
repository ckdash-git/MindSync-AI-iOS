import Foundation

protocol ManageAPIKeyUseCaseProtocol {
    func saveKey(_ key: String) async throws
    func getKey() throws -> String
    func deleteKey() throws
    func hasKey() -> Bool
}

final class ManageAPIKeyUseCase: ManageAPIKeyUseCaseProtocol {

    private let apiKeyRepository: APIKeyRepositoryProtocol
    private let networkManager: NetworkManagerProtocol

    init(
        apiKeyRepository: APIKeyRepositoryProtocol,
        networkManager: NetworkManagerProtocol
    ) {
        self.apiKeyRepository = apiKeyRepository
        self.networkManager = networkManager
    }

    func saveKey(_ key: String) async throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.custom(message: "API key cannot be empty.")
        }

        // Save first so the interceptor can inject it during health check validation.
        try apiKeyRepository.saveKey(trimmed)

        do {
            _ = try await networkManager.request(HealthEndpoint(), responseType: HealthResponseDTO.self)
        } catch {
            // Rollback the saved key if validation fails.
            try? apiKeyRepository.deleteKey()
            throw AppError.custom(message: "Invalid API key. Verification failed.")
        }

        logInfo("Saved OpenRouter API key")
    }

    func getKey() throws -> String {
        try apiKeyRepository.getKey()
    }

    func deleteKey() throws {
        try apiKeyRepository.deleteKey()
        logInfo("Deleted OpenRouter API key")
    }

    func hasKey() -> Bool {
        apiKeyRepository.hasKey()
    }
}
