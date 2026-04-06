import Foundation

struct ExplainEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { "/api/v1/explain" }
    var method: HTTPMethod { .post }
    var requiresStreaming: Bool { true }

    var headers: [String: String] {
        ["Authorization": "Bearer \(apiKey)"]
    }

    var body: Encodable? { requestBody }

    private let apiKey: String
    private let requestBody: ExplainRequestDTO

    init(apiKey: String, requestBody: ExplainRequestDTO) {
        self.apiKey = apiKey
        self.requestBody = requestBody
    }
}
