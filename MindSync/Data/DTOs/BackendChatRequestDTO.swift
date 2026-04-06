import Foundation

struct BackendChatRequestDTO: Encodable {
    let message: String
    let model: String
}
