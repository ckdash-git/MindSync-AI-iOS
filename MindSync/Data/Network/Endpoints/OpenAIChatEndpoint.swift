import Foundation

struct OpenAIChatEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.openAIBaseURL }
    var path: String { "/chat/completions" }
    var method: HTTPMethod { .post }
    var requiresStreaming: Bool { true }

    var headers: [String: String] {
        ["Authorization": "Bearer \(apiKey)"]
    }

    var body: Encodable? { requestBody }

    private let apiKey: String
    private let requestBody: OpenAIChatRequestDTO

    init(apiKey: String, requestBody: OpenAIChatRequestDTO) {
        self.apiKey = apiKey
        self.requestBody = requestBody
    }
}
