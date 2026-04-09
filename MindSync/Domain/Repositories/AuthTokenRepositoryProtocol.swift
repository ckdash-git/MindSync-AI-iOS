import Foundation

/// Protocol for storing and retrieving backend auth tokens.
protocol AuthTokenRepositoryProtocol {
    // MARK: Access token
    func saveAccessToken(_ token: String) throws
    func getAccessToken() throws -> String
    func deleteAccessToken() throws
    func hasAccessToken() -> Bool

    // MARK: Refresh token
    func saveRefreshToken(_ token: String) throws
    func getRefreshToken() throws -> String
    func deleteRefreshToken() throws
}
