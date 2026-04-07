import Foundation

struct AICouncilEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { "/api/v1/ai-council" }
    var method: HTTPMethod { .post }
    var requiresStreaming: Bool { true }
    var headers: [String: String] { ["Accept": "text/event-stream"] }
    var body: Encodable? { requestBody }

    private let requestBody: AICouncilRequestDTO

    init(requestBody: AICouncilRequestDTO) {
        self.requestBody = requestBody
    }
}
