#if DEBUG
import Foundation

/// No-op mock for SwiftUI previews — avoids hitting Firebase.
final class MockAuthUseCase: AuthUseCaseProtocol {
    var currentUser: AppUser? = nil

    func signIn(email: String, password _: String) async throws -> AppUser {
        AppUser(id: "mock", email: email, displayName: "Preview User", photoURL: nil, isEmailVerified: true)
    }

    func signUp(email: String, password _: String, displayName: String) async throws -> AppUser {
        AppUser(id: "mock", email: email, displayName: displayName, photoURL: nil, isEmailVerified: false)
    }

    func signInWithGoogle() async throws -> AppUser {
        AppUser(id: "mock-google", email: "google@example.com", displayName: "Google User", photoURL: nil, isEmailVerified: true)
    }

    func signInWithGitHub() async throws -> AppUser {
        AppUser(id: "mock-github", email: "github@example.com", displayName: "GitHub User", photoURL: nil, isEmailVerified: true)
    }

    func sendPasswordReset(to _: String) async throws {
        // No-op: preview stub — no Firebase in SwiftUI previews.
    }

    func signOut() throws {
        // No-op: preview stub — no auth state to clear.
    }

    func authStateChanges() -> AsyncStream<AppUser?> {
        AsyncStream { $0.finish() }
    }
}

/// In-memory no-op token repository used only in SwiftUI previews.
final class MockAuthTokenRepository: AuthTokenRepositoryProtocol {
    private var token: String?
    func saveAccessToken(_ t: String) throws { token = t }
    func getAccessToken() throws -> String {
        guard let t = token else { throw AppError.unauthorized }
        return t
    }
    func deleteAccessToken() throws { token = nil }
    func hasAccessToken() -> Bool { token != nil }
}
#endif
