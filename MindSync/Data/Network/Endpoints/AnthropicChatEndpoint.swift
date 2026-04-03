import Foundation

struct AnthropicChatEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.anthropicBaseURL }
    var path: String { "/messages" }
    var method: HTTPMethod { .post }
    var requiresStreaming: Bool { true }

    var headers: [String: String] {
        [
            "x-api-key": apiKey,
            "anthropic-version": AppConstants.API.anthropicVersion
        ]
    }

    var body: Encodable? { requestBody }

    private let apiKey: String
    private let requestBody: AnthropicChatRequestDTO

    init(apiKey: String, requestBody: AnthropicChatRequestDTO) {
        self.apiKey = apiKey
        self.requestBody = requestBody
    }
}
