import Foundation

struct SessionSummaryEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { "/api/v1/session/summary" }
    var method: HTTPMethod { .post }
    var headers: [String: String] { [:] }
    var body: Encodable? { requestBody }

    private let requestBody: SessionSummaryRequestDTO

    init(requestBody: SessionSummaryRequestDTO) {
        self.requestBody = requestBody
    }
}
