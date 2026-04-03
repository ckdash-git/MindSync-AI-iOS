import Foundation

enum NetworkError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case statusCode(Int)
    case decodingError
    case noData
    case cancelled
    case streamEnded
    case underlying(String)

    static func map(from error: Error, statusCode: Int? = nil) -> AppError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .timeout
            case .cancelled:
                return .custom(message: "Request was cancelled.")
            default:
                return .custom(message: "Network error occurred.")
            }
        }

        if let code = statusCode {
            switch code {
            case 401: return .unauthorized
            case 400..<500: return .requestFailed(statusCode: code)
            case 500..<600: return .serverError(message: "Server returned \(code)")
            default: return .requestFailed(statusCode: code)
            }
        }

        return .unknown
    }
}
