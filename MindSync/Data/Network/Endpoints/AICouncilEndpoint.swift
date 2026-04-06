import Foundation

struct AICouncilEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { "/api/v1/ai-council" }
    var method: HTTPMethod { .post }
    var requiresStreaming: Bool { true }

    var headers: [String: String] {
        ["Authorization": "Bearer \(apiKey)"]
    }

    var body: Encodable? { requestBody }

    private let apiKey: String
    private let requestBody: AICouncilRequestDTO

    init(apiKey: String, requestBody: AICouncilRequestDTO) {
        self.apiKey = apiKey
        self.requestBody = requestBody
    }
}
