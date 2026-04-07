import Foundation

struct ChatNonStreamResponseDTO: Decodable, Sendable {
    struct ChatData: Decodable, Sendable {
        let chatId: String
        let response: String
        let model: String
        let tokensUsed: Int
    }
    let success: Bool
    let data: ChatData
}
