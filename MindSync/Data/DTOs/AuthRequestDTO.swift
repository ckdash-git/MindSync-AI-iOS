import Foundation

struct AuthRequestDTO: Encodable {
    let email: String
    let password: String
    /// Required for registration. Encodes as `display_name` via `.convertToSnakeCase`.
    let displayName: String?

    init(email: String, password: String, displayName: String? = nil) {
        self.email = email
        self.password = password
        self.displayName = displayName
    }
}
