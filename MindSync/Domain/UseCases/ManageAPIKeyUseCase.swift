import Foundation

protocol ManageAPIKeyUseCaseProtocol {
    func saveKey(_ key: String, for provider: AIProvider) throws
    func getKey(for provider: AIProvider) throws -> String
    func deleteKey(for provider: AIProvider) throws
    func hasKey(for provider: AIProvider) -> Bool
}

final class ManageAPIKeyUseCase: ManageAPIKeyUseCaseProtocol {

    private let apiKeyRepository: APIKeyRepositoryProtocol

    init(apiKeyRepository: APIKeyRepositoryProtocol) {
        self.apiKeyRepository = apiKeyRepository
    }

    func saveKey(_ key: String, for provider: AIProvider) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.custom(message: "API key cannot be empty.")
        }
        try apiKeyRepository.saveKey(trimmed, for: provider)
        logInfo("Saved API key for provider: \(provider.displayName)")
    }

    func getKey(for provider: AIProvider) throws -> String {
        try apiKeyRepository.getKey(for: provider)
    }

    func deleteKey(for provider: AIProvider) throws {
        try apiKeyRepository.deleteKey(for: provider)
        logInfo("Deleted API key for provider: \(provider.displayName)")
    }

    func hasKey(for provider: AIProvider) -> Bool {
        apiKeyRepository.hasKey(for: provider)
    }
}
