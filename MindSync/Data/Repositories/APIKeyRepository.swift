import Foundation

final class APIKeyRepository: APIKeyRepositoryProtocol {

    private let keychainManager: KeychainManagerProtocol

    init(keychainManager: KeychainManagerProtocol) {
        self.keychainManager = keychainManager
    }

    func saveKey(_ key: String, for provider: AIProvider) throws {
        try keychainManager.save(key, for: provider.keychainAccount)
    }

    func getKey(for provider: AIProvider) throws -> String {
        try keychainManager.retrieve(for: provider.keychainAccount)
    }

    func deleteKey(for provider: AIProvider) throws {
        try keychainManager.delete(for: provider.keychainAccount)
    }

    func hasKey(for provider: AIProvider) -> Bool {
        (try? keychainManager.retrieve(for: provider.keychainAccount)) != nil
    }
}
