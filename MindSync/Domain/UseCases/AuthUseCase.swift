import Foundation

/// Use-case protocol for authentication actions.
protocol AuthUseCaseProtocol {
    var currentUser: AppUser? { get }
    func signIn(email: String, password: String) async throws -> AppUser
    func signUp(email: String, password: String, displayName: String) async throws -> AppUser
    func signInWithGoogle() async throws -> AppUser
    func signInWithGitHub() async throws -> AppUser
    func sendPasswordReset(to email: String) async throws
    func signOut() throws
    func authStateChanges() -> AsyncStream<AppUser?>
}

/// Concrete use case — thin pass-through today, but gives us a place
/// to add analytics, validation, or cross-cutting logic later.
final class AuthUseCase: AuthUseCaseProtocol {

    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    var currentUser: AppUser? { repository.currentUser }

    func signIn(email: String, password: String) async throws -> AppUser {
        try await repository.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String, displayName: String) async throws -> AppUser {
        try await repository.signUp(email: email, password: password, displayName: displayName)
    }

    func signInWithGoogle() async throws -> AppUser {
        try await repository.signInWithGoogle()
    }

    func signInWithGitHub() async throws -> AppUser {
        try await repository.signInWithGitHub()
    }

    func sendPasswordReset(to email: String) async throws {
        try await repository.sendPasswordReset(to: email)
    }

    func signOut() throws {
        try repository.signOut()
    }

    func authStateChanges() -> AsyncStream<AppUser?> {
        repository.authStateChanges()
    }
}
