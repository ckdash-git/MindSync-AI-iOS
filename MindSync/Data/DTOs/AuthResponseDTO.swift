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

            nonisolated init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                accessToken = try container.decode(String.self, forKey: .accessToken)
                refreshToken = try container.decode(String.self, forKey: .refreshToken)
            }

            private enum CodingKeys: String, CodingKey {
                case accessToken, refreshToken
            }
        }

        struct BackendUser: Decodable, Sendable {
            let id: String
            let email: String
            /// Field `display_name` → `displayName` via `.convertFromSnakeCase`.
            let displayName: String?

            nonisolated init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                id = try container.decode(String.self, forKey: .id)
                email = try container.decode(String.self, forKey: .email)
                displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
            }

            private enum CodingKeys: String, CodingKey {
                case id, email, displayName
            }
        }

        let user: BackendUser
        let tokens: Tokens

        nonisolated init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            user = try container.decode(BackendUser.self, forKey: .user)
            tokens = try container.decode(Tokens.self, forKey: .tokens)
        }

        private enum CodingKeys: String, CodingKey {
            case user, tokens
        }
    }

    let success: Bool
    let data: AuthData?

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        data = try container.decodeIfPresent(AuthData.self, forKey: .data)
    }

    private enum CodingKeys: String, CodingKey {
        case success, data
    }
}
