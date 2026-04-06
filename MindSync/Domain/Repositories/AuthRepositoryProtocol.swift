import Foundation

/// Protocol defining authentication operations.
/// Concrete implementations (Firebase, mock, etc.) conform to this.
protocol AuthRepositoryProtocol {

    /// The currently authenticated user, if any.
    var currentUser: AppUser? { get }

    /// Sign in with email and password.
    func signIn(email: String, password: String) async throws -> AppUser

    /// Create a new account with email, password, and display name.
    func signUp(email: String, password: String, displayName: String) async throws -> AppUser

    /// Sign in (or sign up) with Google.
    func signInWithGoogle() async throws -> AppUser

    /// Sign in (or sign up) with GitHub.
    func signInWithGitHub() async throws -> AppUser

    /// Send a password-reset email.
    func sendPasswordReset(to email: String) async throws

    /// Sign out the current user.
    func signOut() throws

    /// Observe auth-state changes. Returns a stream of optional `AppUser`.
    func authStateChanges() -> AsyncStream<AppUser?>
}
