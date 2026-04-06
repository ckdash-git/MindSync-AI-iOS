import Foundation

struct BackendChatEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { "/api/v1/chat" }
    var method: HTTPMethod { .post }
    var requiresStreaming: Bool { true }

    var headers: [String: String] {
        ["Authorization": "Bearer \(apiKey)"]
    }

    var body: Encodable? { requestBody }

    private let apiKey: String
    private let requestBody: BackendChatRequestDTO

    init(apiKey: String, requestBody: BackendChatRequestDTO) {
        self.apiKey = apiKey
        self.requestBody = requestBody
    }
}
