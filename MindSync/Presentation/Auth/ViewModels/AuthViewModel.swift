import Foundation
import SwiftUI
import Combine

/// Centralised view-model for login, sign-up, and password-reset flows.
@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published State

    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    @Published var resetEmailSent = false
    @Published var showResetAlert = false

    @Published private(set) var currentUser: AppUser?

    /// `true` only when a valid backend JWT exists in Keychain.
    /// NOT driven by Firebase session state.
    @Published private(set) var isAuthenticated = false

    // MARK: - Dependencies

    private let authUseCase: AuthUseCaseProtocol
    private let authTokenRepository: AuthTokenRepositoryProtocol

    // MARK: - Lifecycle

    init(authUseCase: AuthUseCaseProtocol, authTokenRepository: AuthTokenRepositoryProtocol) {
        self.authUseCase = authUseCase
        self.authTokenRepository = authTokenRepository
        self.currentUser = authUseCase.currentUser
        // Auth state is based on JWT presence — not on Firebase session.
        self.isAuthenticated = authTokenRepository.hasAccessToken()
    }

    // MARK: - Auth State Listener

    /// Keeps `currentUser` in sync with Firebase state (display purposes).
    /// Also watches for backend 401 → forces logout.
    /// `isAuthenticated` is managed directly by signIn/signOut actions and the 401 trap.
    func listenToAuthState() async {
        // Concurrent task: handle backend session expiry (401 from any protected endpoint).
        Task {
            for await _ in NotificationCenter.default.notifications(named: .backendSessionExpired) {
                forceSignOut()
            }
        }

        // Main loop: keep currentUser display info up to date from Firebase.
        for await user in authUseCase.authStateChanges() {
            currentUser = user
        }
    }

    // MARK: - Sign In

    func signIn() {
        guard validateSignInFields() else { return }

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let user = try await authUseCase.signIn(email: email.trimmed, password: password)
                currentUser = user
                isAuthenticated = true
                clearFields()
                logInfo("Sign-in successful for user \(user.id)")
            } catch {
                presentError(error)
            }
        }
    }

    // MARK: - Sign Up

    func signUp() {
        guard validateSignUpFields() else { return }

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let user = try await authUseCase.signUp(
                    email: email.trimmed,
                    password: password,
                    displayName: fullName.trimmed
                )
                currentUser = user
                isAuthenticated = true
                clearFields()
                logInfo("Sign-up successful for user \(user.id)")
            } catch {
                presentError(error)
            }
        }
    }

    // MARK: - Password Reset

    func sendPasswordReset() {
        let trimmedEmail = email.trimmed
        guard !trimmedEmail.isEmpty else {
            presentError("Please enter your email address first.")
            return
        }

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await authUseCase.sendPasswordReset(to: trimmedEmail)
                resetEmailSent = true
                showResetAlert = true
                logInfo("Password reset email sent")
            } catch {
                presentError(error)
            }
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let user = try await authUseCase.signInWithGoogle()
                currentUser = user
                isAuthenticated = true
                clearFields()
                logInfo("Google sign-in successful for user \(user.id)")
            } catch {
                if (error as? AppError) == .userCancelled {
                    logInfo("Google sign-in cancelled by user")
                    return
                }
                presentError(error)
            }
        }
    }

    // MARK: - GitHub Sign-In

    func signInWithGitHub() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let user = try await authUseCase.signInWithGitHub()
                currentUser = user
                isAuthenticated = true
                clearFields()
                logInfo("GitHub sign-in successful for user \(user.id)")
            } catch {
                if (error as? AppError) == .userCancelled {
                    logInfo("GitHub sign-in cancelled by user")
                    return
                }
                presentError(error)
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try authUseCase.signOut()
            currentUser = nil
            isAuthenticated = false
            logInfo("User signed out")
        } catch {
            presentError(error)
        }
    }

    // MARK: - Session Expiry (401)

    /// Called when the backend returns 401 on a protected endpoint.
    /// Clears all auth state and redirects to the login screen.
    private func forceSignOut() {
        logWarning("Backend session expired — forcing logout")
        try? authUseCase.signOut()
        currentUser = nil
        isAuthenticated = false
        presentError("Session expired. Please sign in again.")
    }

    // MARK: - Validation

    private func validateSignInFields() -> Bool {
        let trimmedEmail = email.trimmed
        if trimmedEmail.isEmpty {
            presentError("Please enter your email address.")
            return false
        }
        if !trimmedEmail.isValidEmail {
            presentError("Please enter a valid email address.")
            return false
        }
        if password.isEmpty {
            presentError("Please enter your password.")
            return false
        }
        return true
    }

    private func validateSignUpFields() -> Bool {
        let trimmedName = fullName.trimmed
        if trimmedName.isEmpty {
            presentError("Please enter your full name.")
            return false
        }
        if trimmedName.count < 2 {
            presentError("Name must be at least 2 characters.")
            return false
        }
        guard validateSignInFields() else { return false }
        if password.count < 8 {
            presentError("Password must be at least 8 characters.")
            return false
        }
        return true
    }

    // MARK: - Helpers

    private func clearFields() {
        email = ""
        password = ""
        fullName = ""
    }

    private func presentError(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        presentError(message)
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showError = true
        logWarning("Auth error: \(message)")
    }
}

// MARK: - String Helpers

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }
}
