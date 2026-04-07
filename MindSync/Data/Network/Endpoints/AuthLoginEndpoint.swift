import Foundation

struct AuthLoginEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { "/api/v1/auth/login" }
    var method: HTTPMethod { .post }
    var headers: [String: String] { [:] }
    var body: Encodable? { requestBody }

    private let requestBody: AuthRequestDTO

    init(email: String, password: String) {
        self.requestBody = AuthRequestDTO(email: email, password: password)
    }
}
