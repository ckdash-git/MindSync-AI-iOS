import Foundation

enum AppConstants {

    enum API {
        static let openAIBaseURL = "https://api.openai.com/v1"
        static let anthropicBaseURL = "https://api.anthropic.com/v1"
        static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta"

        static let defaultTimeoutInterval: TimeInterval = 60
        static let streamingTimeoutInterval: TimeInterval = 180
    }

    enum Keychain {
        static let service = "com.mindsync.keychain"
        static let openAIKeyAccount = "openai_api_key"
        static let anthropicKeyAccount = "anthropic_api_key"
        static let geminiKeyAccount = "gemini_api_key"
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
