import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

/// Firebase-backed implementation of `AuthRepositoryProtocol`.
final class FirebaseAuthRepository: AuthRepositoryProtocol {

    // MARK: - Properties

    private let auth: Auth

    init(auth: Auth = Auth.auth()) {
        self.auth = auth
    }

    // MARK: - Current User

    var currentUser: AppUser? {
        auth.currentUser.map { $0.toAppUser() }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> AppUser {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            logInfo("User signed in: \(result.user.uid)")
            return result.user.toAppUser()
        } catch {
            logError("Sign-in failed: \(error.localizedDescription)")
            throw error.toAppError()
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, displayName: String) async throws -> AppUser {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)

            // Set the display name on the newly created profile
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            // Reload so the local user object picks up the new name
            try await result.user.reload()

            let user = Auth.auth().currentUser ?? result.user
            logInfo("User signed up: \(user.uid)")
            return user.toAppUser()
        } catch {
            logError("Sign-up failed: \(error.localizedDescription)")
            throw error.toAppError()
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async throws -> AppUser {
        // 1. Get the client ID from the Firebase config
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AppError.custom(message: "Firebase client ID not found. Ensure GoogleService-Info.plist is configured.")
        }

        // 2. Get the presenting view controller
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw AppError.custom(message: "Unable to find root view controller for Google Sign-In.")
        }

        // 3. Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // 4. Present the Google Sign-In flow
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AppError.custom(message: "Failed to retrieve Google ID token.")
            }

            let accessToken = result.user.accessToken.tokenString

            // 5. Create Firebase credential from Google tokens
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            // 6. Sign in to Firebase with the Google credential
            let authResult = try await auth.signIn(with: credential)
            logInfo("Google sign-in successful: \(authResult.user.uid)")
            return authResult.user.toAppUser()
        } catch {
            // User cancelled the Google Sign-In flow
            if (error as NSError).code == GIDSignInError.canceled.rawValue {
                throw AppError.custom(message: "Google Sign-In was cancelled.")
            }
            logError("Google sign-in failed: \(error.localizedDescription)")
            throw error.toAppError()
        }
    }

    // MARK: - Password Reset

    func sendPasswordReset(to email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
            logInfo("Password-reset email sent to \(email)")
        } catch {
            logError("Password reset failed: \(error.localizedDescription)")
            throw error.toAppError()
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        do {
            // Sign out from Google as well
            GIDSignIn.sharedInstance.signOut()
            try auth.signOut()
            logInfo("User signed out")
        } catch {
            logError("Sign-out failed: \(error.localizedDescription)")
            throw error.toAppError()
        }
    }

    // MARK: - Auth State Observer

    func authStateChanges() -> AsyncStream<AppUser?> {
        AsyncStream { continuation in
            let handle = auth.addStateDidChangeListener { _, user in
                continuation.yield(user?.toAppUser())
            }
            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }
}

// MARK: - Firebase User → AppUser Mapping

private extension FirebaseAuth.User {
    func toAppUser() -> AppUser {
        AppUser(
            id: uid,
            email: email ?? "",
            displayName: displayName,
            photoURL: photoURL,
            isEmailVerified: isEmailVerified
        )
    }
}

// MARK: - Firebase Error → AppError Mapping

private extension Error {
    func toAppError() -> AppError {
        let nsError = self as NSError
        guard nsError.domain == AuthErrorDomain else {
            return .custom(message: localizedDescription)
        }

        switch AuthErrorCode(rawValue: nsError.code) {
        case .invalidEmail:
            return .custom(message: "The email address is invalid.")
        case .emailAlreadyInUse:
            return .custom(message: "This email is already registered. Try signing in instead.")
        case .weakPassword:
            return .custom(message: "Password is too weak. Use at least 6 characters.")
        case .wrongPassword, .invalidCredential:
            return .custom(message: "Incorrect email or password.")
        case .userNotFound:
            return .custom(message: "No account found with this email.")
        case .userDisabled:
            return .custom(message: "This account has been disabled.")
        case .tooManyRequests:
            return .custom(message: "Too many attempts. Please try again later.")
        case .networkError:
            return .networkUnavailable
        default:
            return .custom(message: localizedDescription)
        }
    }
}
