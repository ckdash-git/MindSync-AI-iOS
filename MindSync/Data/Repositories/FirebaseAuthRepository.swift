import Foundation
import UIKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

/// Firebase-backed implementation of `AuthRepositoryProtocol`.
///
/// Auth state model:
/// - The user is considered **authenticated** when a backend JWT exists in Keychain.
/// - Firebase session is maintained alongside for password-reset and social-auth support,
///   but it is NOT the source of truth for app authentication.
final class FirebaseAuthRepository: AuthRepositoryProtocol {

    // MARK: - Properties

    private let auth: Auth
    private let networkManager: NetworkManagerProtocol
    private let authTokenRepository: AuthTokenRepositoryProtocol

    init(
        auth: Auth = Auth.auth(),
        networkManager: NetworkManagerProtocol,
        authTokenRepository: AuthTokenRepositoryProtocol
    ) {
        self.auth = auth
        self.networkManager = networkManager
        self.authTokenRepository = authTokenRepository
    }

    // MARK: - Current User

    var currentUser: AppUser? {
        auth.currentUser.map { $0.toAppUser() }
    }

    // MARK: - Sign In

    /// Authenticates with the MindSync backend (primary), then signs into Firebase
    /// (secondary — enables password reset).
    func signIn(email: String, password: String) async throws -> AppUser {
        // 1. Backend authentication — JWT is the source of auth truth.
        do {
            let endpoint = AuthLoginEndpoint(email: email, password: password)
            let response = try await networkManager.request(endpoint, responseType: AuthResponseDTO.self)
            guard let tokens = response.data?.tokens else {
                throw AppError.custom(message: "Sign-in failed: server did not return a token.")
            }
            try authTokenRepository.saveAccessToken(tokens.accessToken)
            logInfo("Backend JWT stored for \(email)")
        } catch let error as AppError {
            // Map 401 from /auth/login to a user-friendly wrong-password message.
            if case .unauthorized = error {
                throw AppError.custom(message: "Incorrect email or password.")
            }
            throw error
        } catch {
            throw AppError.custom(message: "Sign-in failed: \(error.localizedDescription)")
        }

        // 2. Firebase sign-in — non-critical; enables password-reset emails.
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            logInfo("Firebase session created for \(result.user.uid)")
            return result.user.toAppUser()
        } catch {
            logWarning("Firebase sign-in failed (non-critical): \(error.localizedDescription)")
            // Backend auth succeeded — return a minimal user from the email.
            return AppUser(id: email, email: email, displayName: nil, photoURL: nil, isEmailVerified: false)
        }
    }

    // MARK: - Sign Up

    /// Registers with the MindSync backend (primary), then creates a Firebase account
    /// (secondary — enables password reset).
    func signUp(email: String, password: String, displayName: String) async throws -> AppUser {
        // 1. Backend registration.
        do {
            let endpoint = AuthRegisterEndpoint(email: email, password: password, displayName: displayName)
            let response = try await networkManager.request(endpoint, responseType: AuthResponseDTO.self)
            guard let tokens = response.data?.tokens else {
                throw AppError.custom(message: "Registration failed: server did not return a token.")
            }
            try authTokenRepository.saveAccessToken(tokens.accessToken)
            logInfo("Backend JWT stored (sign-up) for \(email)")
        } catch let error as AppError {
            if case .requestFailed(let code) = error, code == 409 {
                throw AppError.custom(message: "This email is already registered. Try signing in instead.")
            }
            if case .unauthorized = error {
                throw AppError.custom(message: "Registration failed. Please try again.")
            }
            throw error
        } catch {
            throw AppError.custom(message: "Registration failed: \(error.localizedDescription)")
        }

        // 2. Firebase account creation — non-critical.
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            try await result.user.reload()
            let user = self.auth.currentUser ?? result.user
            logInfo("Firebase account created for \(user.uid)")
            return user.toAppUser()
        } catch {
            logWarning("Firebase account creation failed (non-critical): \(error.localizedDescription)")
            return AppUser(id: email, email: email, displayName: displayName, photoURL: nil, isEmailVerified: false)
        }
    }

    // MARK: - Google Sign-In

    /// Performs Google OAuth via Firebase, then exchanges the Firebase ID token
    /// for a backend JWT via `POST /api/v1/auth/social-login`.
    ///
    /// If the backend endpoint does not exist, signs out and shows a user-facing error.
    func signInWithGoogle() async throws -> AppUser {
        // Step 1: Google OAuth via Firebase.
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AppError.custom(message: "Firebase client ID not found.")
        }

        let rootViewController = try await MainActor.run {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                throw AppError.custom(message: "Unable to find root view controller for Google Sign-In.")
            }
            return rootVC
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let gidResult: GIDSignInResult
        do {
            gidResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        } catch {
            if (error as NSError).code == GIDSignInError.canceled.rawValue {
                throw AppError.userCancelled
            }
            logError("Google sign-in failed: \(error.localizedDescription)")
            throw error.toAppError()
        }

        guard let googleIDToken = gidResult.user.idToken?.tokenString else {
            throw AppError.custom(message: "Failed to retrieve Google ID token.")
        }

        // Step 2: Sign into Firebase with Google credential → get Firebase ID token.
        let credential = GoogleAuthProvider.credential(
            withIDToken: googleIDToken,
            accessToken: gidResult.user.accessToken.tokenString
        )
        let authResult: AuthDataResult
        do {
            authResult = try await auth.signIn(with: credential)
        } catch {
            GIDSignIn.sharedInstance.signOut()
            throw error.toAppError()
        }

        // Step 3: Exchange Firebase ID token with backend.
        do {
            let firebaseIDToken = try await authResult.user.getIDToken()
            let endpoint = AuthSocialLoginEndpoint(provider: "google", idToken: firebaseIDToken)
            let response = try await networkManager.request(endpoint, responseType: AuthResponseDTO.self)
            guard let tokens = response.data?.tokens else {
                throw AppError.custom(message: "Social login failed: no token returned.")
            }
            try authTokenRepository.saveAccessToken(tokens.accessToken)
            logInfo("Google sign-in: backend JWT stored for \(authResult.user.uid)")
            return authResult.user.toAppUser()
        } catch {
            // Backend social-login not supported yet — clean up both sessions.
            try? auth.signOut()
            GIDSignIn.sharedInstance.signOut()
            logWarning("Backend social-login unavailable: \(error.localizedDescription)")
            throw AppError.custom(message: "Social login not supported yet. Please use email/password.")
        }
    }

    // MARK: - GitHub Sign-In

    /// Performs GitHub OAuth via Firebase, then exchanges the Firebase ID token
    /// for a backend JWT via `POST /api/v1/auth/social-login`.
    ///
    /// If the backend endpoint does not exist, signs out and shows a user-facing error.
    func signInWithGitHub() async throws -> AppUser {
        // Step 1: GitHub OAuth via Firebase.
        let provider = OAuthProvider(providerID: "github.com")
        provider.scopes = ["user:email"]

        let authResult: AuthDataResult
        do {
            let credential = try await provider.credential(with: nil)
            authResult = try await auth.signIn(with: credential)
        } catch {
            let nsError = error as NSError
            if nsError.code == AuthErrorCode.webContextCancelled.rawValue ||
               nsError.code == AuthErrorCode.webContextAlreadyPresented.rawValue {
                throw AppError.userCancelled
            }
            logError("GitHub sign-in failed: \(error.localizedDescription)")
            throw error.toAppError()
        }

        // Step 2: Exchange Firebase ID token with backend.
        do {
            let firebaseIDToken = try await authResult.user.getIDToken()
            let endpoint = AuthSocialLoginEndpoint(provider: "github", idToken: firebaseIDToken)
            let response = try await networkManager.request(endpoint, responseType: AuthResponseDTO.self)
            guard let tokens = response.data?.tokens else {
                throw AppError.custom(message: "Social login failed: no token returned.")
            }
            try authTokenRepository.saveAccessToken(tokens.accessToken)
            logInfo("GitHub sign-in: backend JWT stored for \(authResult.user.uid)")
            return authResult.user.toAppUser()
        } catch {
            // Backend social-login not supported — clean up Firebase session.
            try? auth.signOut()
            logWarning("Backend social-login unavailable: \(error.localizedDescription)")
            throw AppError.custom(message: "Social login not supported yet. Please use email/password.")
        }
    }

    // MARK: - Password Reset

    /// Uses Firebase to send a password-reset email.
    /// The user must still sign in via the backend after resetting their password.
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

    /// Clears the backend JWT and signs out of all Firebase/social sessions.
    func signOut() throws {
        // Clear backend JWT — this is the primary auth token.
        try? authTokenRepository.deleteAccessToken()
        // Sign out from social providers.
        GIDSignIn.sharedInstance.signOut()
        // Sign out from Firebase.
        do {
            try auth.signOut()
            logInfo("User signed out")
        } catch {
            logError("Firebase sign-out failed: \(error.localizedDescription)")
            throw error.toAppError()
        }
    }

    // MARK: - Auth State Observer

    /// Returns a stream of Firebase user objects.
    /// Used to keep `AuthViewModel.currentUser` up to date for display purposes only.
    /// `isAuthenticated` must be derived from JWT presence, not from this stream.
    func authStateChanges() -> AsyncStream<AppUser?> {
        let authInstance = self.auth
        return AsyncStream { continuation in
            let handle = authInstance.addStateDidChangeListener { _, user in
                continuation.yield(user?.toAppUser())
            }
            continuation.onTermination = { _ in
                authInstance.removeStateDidChangeListener(handle)
            }
        }
    }
}

// MARK: - Firebase User → AppUser Mapping

private extension FirebaseAuth.User {
    func toAppUser() -> AppUser {
        AppUser(
            id: uid,
            email: email,
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
