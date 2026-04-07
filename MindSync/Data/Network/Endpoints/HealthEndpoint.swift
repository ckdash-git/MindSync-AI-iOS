import Foundation

struct HealthEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { "/health" }
    var method: HTTPMethod { .get }
    var headers: [String: String] { [:] }
}
