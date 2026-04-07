import Foundation

/// Protocol for storing and retrieving the backend JWT access token.
protocol AuthTokenRepositoryProtocol {
    func saveAccessToken(_ token: String) throws
    func getAccessToken() throws -> String
    func deleteAccessToken() throws
    func hasAccessToken() -> Bool
}
