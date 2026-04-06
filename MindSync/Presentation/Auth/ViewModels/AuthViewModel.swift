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
    @Published private(set) var isAuthenticated = false

    // MARK: - Dependencies

    private let authUseCase: AuthUseCaseProtocol

    // MARK: - Lifecycle

    init(authUseCase: AuthUseCaseProtocol) {
        self.authUseCase = authUseCase
        self.currentUser = authUseCase.currentUser
        self.isAuthenticated = authUseCase.currentUser != nil
    }

    // MARK: - Auth State Listener

    func listenToAuthState() async {
        for await user in authUseCase.authStateChanges() {
            self.currentUser = user
            self.isAuthenticated = user != nil
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
                self.currentUser = user
                self.isAuthenticated = true
                clearFields()
                logInfo("Sign-in successful for \(user.email)")
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
                self.currentUser = user
                self.isAuthenticated = true
                clearFields()
                logInfo("Sign-up successful for \(user.email)")
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
                logInfo("Password reset sent to \(trimmedEmail)")
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
                self.currentUser = user
                self.isAuthenticated = true
                clearFields()
                logInfo("Google sign-in successful for \(user.email)")
            } catch {
                // Don't show error for user cancellation
                if case .custom(let msg) = (error as? AppError), msg.contains("cancelled") {
                    logInfo("Google sign-in cancelled by user")
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
            self.currentUser = nil
            self.isAuthenticated = false
            logInfo("User signed out")
        } catch {
            presentError(error)
        }
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
        if password.count < 6 {
            presentError("Password must be at least 6 characters.")
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
