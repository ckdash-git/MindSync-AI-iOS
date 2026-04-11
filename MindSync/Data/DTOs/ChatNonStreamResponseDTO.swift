import Foundation

struct ChatNonStreamResponseDTO: Decodable, Sendable {
    struct ChatData: Decodable, Sendable {
        let chatId: String
        let response: String
        let model: String
        let tokensUsed: Int

        nonisolated init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            chatId = try container.decode(String.self, forKey: .chatId)
            response = try container.decode(String.self, forKey: .response)
            model = try container.decode(String.self, forKey: .model)
            tokensUsed = try container.decode(Int.self, forKey: .tokensUsed)
        }

        private enum CodingKeys: String, CodingKey {
            case chatId, response, model, tokensUsed
        }
    }

    let success: Bool
    let data: ChatData

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        data = try container.decode(ChatData.self, forKey: .data)
    }

    private enum CodingKeys: String, CodingKey {
        case success, data
    }
}
