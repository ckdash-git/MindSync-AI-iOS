import Foundation

/// Response shape returned by `/api/v1/auth/login`, `/api/v1/auth/register`,
/// and (when implemented) `/api/v1/auth/social-login`.
struct AuthResponseDTO: Decodable, Sendable {

    struct AuthData: Decodable, Sendable {

        struct Tokens: Decodable, Sendable {
            /// JWT access token. Field `access_token` → `accessToken` via `.convertFromSnakeCase`.
            let accessToken: String
            /// Refresh token for future token renewal.
            let refreshToken: String
        }

        struct BackendUser: Decodable, Sendable {
            let id: String
            let email: String
            /// Field `display_name` → `displayName` via `.convertFromSnakeCase`.
            let displayName: String?
        }

        let user: BackendUser
        let tokens: Tokens
    }

    let success: Bool
    let data: AuthData?
}
