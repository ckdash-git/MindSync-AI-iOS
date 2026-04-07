import Foundation

struct SocialLoginRequestDTO: Encodable {
    /// "google" or "github"
    let provider: String
    /// Firebase ID token for the authenticated user.
    /// Encodes as `id_token` via `.convertToSnakeCase`.
    let idToken: String
}
