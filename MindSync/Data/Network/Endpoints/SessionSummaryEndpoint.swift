import Foundation

struct SessionSummaryEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { "/api/v1/session/summary" }
    var method: HTTPMethod { .post }

    var headers: [String: String] {
        ["Authorization": "Bearer \(apiKey)"]
    }

    var body: Encodable? { requestBody }

    private let apiKey: String
    private let requestBody: SessionSummaryRequestDTO

    init(apiKey: String, requestBody: SessionSummaryRequestDTO) {
        self.apiKey = apiKey
        self.requestBody = requestBody
    }
}
