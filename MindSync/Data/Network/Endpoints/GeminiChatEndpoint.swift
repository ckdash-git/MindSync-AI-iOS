import Foundation

struct GeminiChatEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.geminiBaseURL }

    var path: String { "/models/\(modelID):streamGenerateContent" }

    var method: HTTPMethod { .post }
    var requiresStreaming: Bool { true }
    var headers: [String: String] { [:] }

    var queryParameters: [String: String]? {
        ["key": apiKey, "alt": "sse"]
    }

    var body: Encodable? { requestBody }

    private let apiKey: String
    private let modelID: String
    private let requestBody: GeminiChatRequestDTO

    init(apiKey: String, modelID: String, requestBody: GeminiChatRequestDTO) {
        self.apiKey = apiKey
        self.modelID = modelID
        self.requestBody = requestBody
    }
}
