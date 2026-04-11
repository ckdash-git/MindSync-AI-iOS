import Foundation

struct HealthResponseDTO: Decodable, Sendable {
    let status: String

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
    }

    private enum CodingKeys: String, CodingKey {
        case status
    }
}
