import Foundation

final class AuthTokenRepository: AuthTokenRepositoryProtocol {

    private let keychainManager: KeychainManagerProtocol

    init(keychainManager: KeychainManagerProtocol) {
        self.keychainManager = keychainManager
    }

    // MARK: - Access Token

    func saveAccessToken(_ token: String) throws {
        try keychainManager.save(token, for: AppConstants.Keychain.jwtAccessTokenAccount)
    }

    func getAccessToken() throws -> String {
        do {
            return try keychainManager.retrieve(for: AppConstants.Keychain.jwtAccessTokenAccount)
        } catch AppError.keychainFailed(operation: "not-found") {
            throw AppError.unauthorized
        }
    }

    func deleteAccessToken() throws {
        try keychainManager.delete(for: AppConstants.Keychain.jwtAccessTokenAccount)
    }

    func hasAccessToken() -> Bool {
        (try? keychainManager.retrieve(for: AppConstants.Keychain.jwtAccessTokenAccount)) != nil
    }

    // MARK: - Refresh Token

    func saveRefreshToken(_ token: String) throws {
        try keychainManager.save(token, for: AppConstants.Keychain.jwtRefreshTokenAccount)
    }

    func getRefreshToken() throws -> String {
        do {
            return try keychainManager.retrieve(for: AppConstants.Keychain.jwtRefreshTokenAccount)
        } catch AppError.keychainFailed(operation: "not-found") {
            throw AppError.unauthorized
        }
    }

    func deleteRefreshToken() throws {
        try keychainManager.delete(for: AppConstants.Keychain.jwtRefreshTokenAccount)
    }
}
