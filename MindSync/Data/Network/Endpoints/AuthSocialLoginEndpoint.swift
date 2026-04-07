import Foundation

struct AuthSocialLoginEndpoint: APIEndpoint {
    private static let endpointPath = "/api/v1/auth/social-login"

    var baseURL: String { AppConstants.API.backendBaseURL }
    var path: String { Self.endpointPath }
    var method: HTTPMethod { .post }
    var headers: [String: String] { [:] }
    var body: Encodable? { requestBody }

    private let requestBody: SocialLoginRequestDTO

    init(provider: String, idToken: String) {
        self.requestBody = SocialLoginRequestDTO(provider: provider, idToken: idToken)
    }
}
