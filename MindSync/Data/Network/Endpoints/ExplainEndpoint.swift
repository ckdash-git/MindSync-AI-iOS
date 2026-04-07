import Foundation

struct ExplainEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { "/api/v1/explain" }
    var method: HTTPMethod { .post }
    var requiresStreaming: Bool { true }
    var headers: [String: String] { ["Accept": "text/event-stream"] }
    var body: Encodable? { requestBody }

    private let requestBody: ExplainRequestDTO

    init(requestBody: ExplainRequestDTO) {
        self.requestBody = requestBody
    }
}
