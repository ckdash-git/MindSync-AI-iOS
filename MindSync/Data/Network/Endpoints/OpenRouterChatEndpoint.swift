import Foundation

struct OpenRouterChatEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.openRouterBaseURL }
    var path: String { "/chat/completions" }
    var method: HTTPMethod { .post }
    var requiresStreaming: Bool { true }

    var headers: [String: String] {
        [
            "Authorization": "Bearer \(apiKey)",
            "HTTP-Referer": "https://mindsync.app",
            "X-Title": "MindSync AI"
        ]
    }

    var body: Encodable? { requestBody }

    private let apiKey: String
    private let requestBody: OpenRouterChatRequestDTO

    init(apiKey: String, requestBody: OpenRouterChatRequestDTO) {
        self.apiKey = apiKey
        self.requestBody = requestBody
    }
}
