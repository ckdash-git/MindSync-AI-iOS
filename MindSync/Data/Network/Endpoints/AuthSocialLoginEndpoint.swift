import Foundation

struct AuthSocialLoginEndpoint: APIEndpoint {
    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { "/api/v1/auth/social-login" }
    var method: HTTPMethod { .post }
    var headers: [String: String] { [:] }
    var body: Encodable? { requestBody }

    private let requestBody: SocialLoginRequestDTO

    init(provider: String, idToken: String) {
        self.requestBody = SocialLoginRequestDTO(provider: provider, idToken: idToken)
    }
}
