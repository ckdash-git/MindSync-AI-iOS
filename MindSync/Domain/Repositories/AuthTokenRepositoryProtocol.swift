import Foundation

protocol AuthTokenRepositoryProtocol {
    func saveAccessToken(_ token: String) throws
    func getAccessToken() throws -> String
    func deleteAccessToken() throws
    func hasAccessToken() -> Bool
}
