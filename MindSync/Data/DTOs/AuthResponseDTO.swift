import Foundation

struct AuthResponseDTO: Decodable, Sendable {
    struct AuthData: Decodable, Sendable {
        let accessToken: String
    }
    let success: Bool
    let data: AuthData
}
