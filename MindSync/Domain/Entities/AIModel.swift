import Foundation

enum AIProvider: String, CaseIterable, Codable, Identifiable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case gemini = "gemini"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: return "GPT"
        case .anthropic: return "Claude"
        case .gemini: return "Gemini"
        }
    }

    var keychainAccount: String {
        switch self {
        case .openAI: return AppConstants.Keychain.openAIKeyAccount
        case .anthropic: return AppConstants.Keychain.anthropicKeyAccount
        case .gemini: return AppConstants.Keychain.geminiKeyAccount
        }
    }
}

struct AIModel: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let provider: AIProvider
    let contextWindow: Int
    let supportsStreaming: Bool
    let isPro: Bool

    static let gpt4o = AIModel(
        id: "gpt-4o",
        name: "GPT-4o",
        provider: .openAI,
        contextWindow: 128_000,
        supportsStreaming: true,
        isPro: false
    )

    static let claude3Sonnet = AIModel(
        id: "claude-3-5-sonnet-20241022",
        name: "Claude 3.5 Sonnet",
        provider: .anthropic,
        contextWindow: 200_000,
        supportsStreaming: true,
        isPro: false
    )

    static let geminiPro = AIModel(
        id: "gemini-1.5-pro",
        name: "Gemini 1.5 Pro",
        provider: .gemini,
        contextWindow: 1_000_000,
        supportsStreaming: true,
        isPro: false
    )

    static let allModels: [AIModel] = [.gpt4o, .claude3Sonnet, .geminiPro]
}
