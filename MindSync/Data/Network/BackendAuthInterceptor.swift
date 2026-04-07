import Foundation

extension Notification.Name {
    /// Posted by `BackendAuthInterceptor` when the backend returns HTTP 401.
    /// Observers (e.g. `AuthViewModel`) should sign the user out and redirect to login.
    static let backendSessionExpired = Notification.Name("com.mindsync.backendSessionExpired")
}

/// Centralises authentication header injection for MindSync backend calls.
///
/// - Injects `X-OpenRouter-Key` (required on protected routes).
/// - Injects `Authorization: Bearer <jwt>` when a valid token is present.
/// - Skips injection for `/api/v1/auth/` endpoints (login, register, social-login).
/// - Passes non-backend requests (OpenRouter, Anthropic, Gemini) through unchanged.
/// - Posts `.backendSessionExpired` and throws `AppError.unauthorized` on HTTP 401.
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

        // Only touch requests destined for the MindSync backend.
        guard request.url?.host == "ai.api.optionallabs.com" else {
            return request
        }

        let path = request.url?.path ?? ""

        // Auth endpoints carry their own credentials — skip injection.
        guard !path.hasPrefix("/api/v1/auth/") else {
            logDebug("[\(request.httpMethod ?? "?")] \(path) [auth endpoint — no injection]")
            return request
        }

        // JWT — optional: not present before first login.
        if let jwt = try? authTokenRepository.getAccessToken() {
            request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        }

        // OpenRouter key — required for all protected backend endpoints.
        let apiKey = try apiKeyRepository.getKey()
        request.setValue(apiKey, forHTTPHeaderField: "X-OpenRouter-Key")

        logDebug("[\(request.httpMethod ?? "?")] \(path) [X-OpenRouter-Key: ***REDACTED***]")
        return request
    }

    func intercept(response: HTTPURLResponse, data: Data) async throws {
        // Only watch responses from the MindSync backend.
        guard response.url?.host == "ai.api.optionallabs.com" else { return }

        let path = response.url?.path ?? ""

        // Auth endpoints return 401 for wrong credentials — that is expected behaviour,
        // not a session expiry. Let the calling code handle those errors.
        guard !path.hasPrefix("/api/v1/auth/") else { return }

        logDebug("HTTP \(response.statusCode) ← \(path)")

        if response.statusCode == 401 {
            NotificationCenter.default.post(name: .backendSessionExpired, object: nil)
            throw AppError.unauthorized
        }
    }
}
