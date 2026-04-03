import Foundation

protocol APIKeyRepositoryProtocol {
    func saveKey(_ key: String, for provider: AIProvider) throws
    func getKey(for provider: AIProvider) throws -> String
    func deleteKey(for provider: AIProvider) throws
    func hasKey(for provider: AIProvider) -> Bool
}
