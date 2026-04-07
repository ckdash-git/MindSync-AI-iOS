import Foundation

enum AppError: LocalizedError, Equatable {

    // Network
    case networkUnavailable
    case requestFailed(statusCode: Int)
    case decodingFailed
    case timeout
    case unauthorized
    case serverError(message: String)

    // Auth / Keys
    case missingAPIKey(provider: String)
    case invalidAPIKey(provider: String)
    case userCancelled

    // Storage
    case persistenceFailed
    case keychainFailed(operation: String)

    // General
    case unknown
    case custom(message: String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No network connection. Please check your internet settings."
        case .requestFailed(let code):
            return "Request failed with status code \(code)."
        case .decodingFailed:
            return "Failed to process the server response."
        case .timeout:
            return "The request timed out. Please try again."
        case .unauthorized:
            return "Session expired. Please log in again."
        case .serverError:
            return "A server error occurred. Please try again later."
        case .missingAPIKey(let provider):
            return "No API key found for \(provider). Please add your key in Settings."
        case .invalidAPIKey(let provider):
            return "The API key for \(provider) is invalid."
        case .userCancelled:
            return "The operation was cancelled."
        case .persistenceFailed:
            return "Failed to save data locally."
        case .keychainFailed:
            return "A secure storage error occurred."
        case .unknown:
            return "An unexpected error occurred."
        case .custom(let message):
            return message
        }
    }

    var isRetriable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .serverError:
            return true
        default:
            return false
        }
    }
}
