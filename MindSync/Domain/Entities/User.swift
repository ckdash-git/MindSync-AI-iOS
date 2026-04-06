import Foundation

/// Domain entity representing an authenticated user.
struct AppUser: Identifiable, Equatable {
    let id: String
    let email: String
    let displayName: String?
    let photoURL: URL?
    let isEmailVerified: Bool

    var firstName: String? {
        displayName?.components(separatedBy: " ").first
    }
}
