import Foundation

struct SessionSummaryRequestDTO: Encodable {

    struct Message: Encodable {
        let role: String
        let content: String
    }

    let messages: [Message]
}
