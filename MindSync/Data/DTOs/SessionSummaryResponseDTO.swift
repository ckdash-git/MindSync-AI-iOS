import Foundation

struct SessionSummaryResponseDTO: Decodable, Sendable {
    let summary: String

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        summary = try container.decode(String.self, forKey: .summary)
    }

    private enum CodingKeys: String, CodingKey {
        case summary
    }
}
