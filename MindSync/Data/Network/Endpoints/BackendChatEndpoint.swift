import Foundation

struct BackendChatEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { "/api/v1/chat/stream" }
    var method: HTTPMethod { .post }
    var requiresStreaming: Bool { true }
    var headers: [String: String] { ["Accept": "text/event-stream"] }
    var body: Encodable? { requestBody }

    private let requestBody: BackendChatRequestDTO

    init(requestBody: BackendChatRequestDTO) {
        self.requestBody = requestBody
    }
}
