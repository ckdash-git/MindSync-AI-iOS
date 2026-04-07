import Foundation

/// Centralizes backend authentication header injection.
///
/// - Injects `X-OpenRouter-Key: <key>` (required for all non-auth requests).
/// - Injects `Authorization: Bearer <jwt>` when a JWT is present (optional; absent before first login).
/// - Skips injection entirely for `/api/v1/auth/` endpoints (login / register).
/// - Logs request URL and status code at debug level; API key value is always masked.
final class BackendAuthInterceptor: RequestInterceptorProtocol {

    private let apiKeyRepository: APIKeyRepositoryProtocol
    private let authTokenRepository: AuthTokenRepositoryProtocol

    init(
        apiKeyRepository: APIKeyRepositoryProtocol,
        authTokenRepository: AuthTokenRepositoryProtocol
    ) {
        self.apiKeyRepository = apiKeyRepository
        self.authTokenRepository = authTokenRepository
    }

    func intercept(request: URLRequest) async throws -> URLRequest {
        var request = request
        let path = request.url?.path ?? ""

        // Auth endpoints carry their own credentials — skip injection.
        guard !path.hasPrefix("/api/v1/auth/") else {
            logDebug("[\(request.httpMethod ?? "?")] \(path) [auth endpoint — no injection]")
            return request
        }

        // JWT is optional: not present before first login or after logout.
        if let jwt = try? authTokenRepository.getAccessToken() {
            request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        }

        // OpenRouter key is required for all protected endpoints.
        let apiKey = try apiKeyRepository.getKey()
        request.setValue(apiKey, forHTTPHeaderField: "X-OpenRouter-Key")

        logDebug("[\(request.httpMethod ?? "?")] \(request.url?.absoluteString ?? path) [X-OpenRouter-Key: ***REDACTED***]")
        return request
    }

    func intercept(response: HTTPURLResponse, data: Data) async throws {
        logDebug("HTTP \(response.statusCode) ← \(response.url?.path ?? "?")")
        if response.statusCode == 401 {
            throw AppError.unauthorized
        }
    }
}
