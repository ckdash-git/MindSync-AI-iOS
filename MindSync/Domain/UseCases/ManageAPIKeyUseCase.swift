import Foundation

protocol ManageAPIKeyUseCaseProtocol {
    func saveKey(_ key: String) async throws
    func getKey() throws -> String
    func deleteKey() throws
    func hasKey() -> Bool
}

final class ManageAPIKeyUseCase: ManageAPIKeyUseCaseProtocol {

    private let apiKeyRepository: APIKeyRepositoryProtocol

    init(apiKeyRepository: APIKeyRepositoryProtocol) {
        self.apiKeyRepository = apiKeyRepository
    }

    func saveKey(_ key: String) async throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.custom(message: "API key cannot be empty.")
        }
        
        guard let url = URL(string: AppConstants.API.openRouterAuthURL) else {
            throw AppError.custom(message: "Invalid validation URL.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(trimmed)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.custom(message: "Invalid API Key. Verification failed.")
        }
        guard httpResponse.statusCode == 200 else {
            throw AppError.custom(message: "Invalid API Key. Verification failed.")
        }

        try apiKeyRepository.saveKey(trimmed)
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
