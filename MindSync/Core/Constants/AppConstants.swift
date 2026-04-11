import Foundation
import CoreGraphics

enum AppConstants {

    enum API {
        static let backendBaseURL = "https://ai.api.optionallabs.com"
        static let openRouterBaseURL = "https://openrouter.ai/api/v1"

        static let defaultTimeoutInterval: TimeInterval = 60
        static let streamingTimeoutInterval: TimeInterval = 180

        static let defaultMaxTokens = 4096

        enum Auth {
            static let basePath = "/api/v1/auth"
            static let login = basePath + "/login"
            static let register = basePath + "/register"
            static let refresh = basePath + "/refresh"
            static let socialLogin = basePath + "/social-login"
        }
    }

    enum Keychain {
        static let service = "com.mindsync.keychain"
        static let openRouterKeyAccount = "openrouter_api_key"
        static let jwtAccessTokenAccount = "jwt_access_token"
        static let jwtRefreshTokenAccount = "jwt_refresh_token"
    }

    enum Chat {
        static let maxMessageLength = 8000
        static let maxHistoryCount = 100
        static let defaultModel = "gpt-4o"
    }

    enum UI {
        static let animationDuration: Double = 0.3
        static let cornerRadius: CGFloat = 16
        static let messageBubbleCornerRadius: CGFloat = 12
    }
}
