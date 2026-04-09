import Foundation

struct AuthRequestDTO: Encodable {
    let email: String
    let password: String
    /// Required for registration; omitted for login.
    let displayName: String?

    init(email: String, password: String, displayName: String? = nil) {
        self.email = email
        self.password = password
        self.displayName = displayName
    }

    private enum CodingKeys: String, CodingKey {
        case email
        case password
        case displayName = "display_name"
    }
}
