import Foundation

struct AuthRequestDTO: Encodable {
    let email: String
    let password: String
}
