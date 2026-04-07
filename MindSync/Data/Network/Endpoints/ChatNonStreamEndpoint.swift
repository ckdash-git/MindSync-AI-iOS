import Foundation

struct ChatNonStreamEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { "/api/v1/chat" }
    var method: HTTPMethod { .post }
    var headers: [String: String] { [:] }
    var body: Encodable? { requestBody }

    private let requestBody: BackendChatRequestDTO

    init(requestBody: BackendChatRequestDTO) {
        self.requestBody = requestBody
    }
}
