import Foundation
import SwiftUI

enum AIProvider: String, CaseIterable, Codable, Identifiable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case gemini = "gemini"
    case nvidia = "nvidia"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: return "GPT"
        case .anthropic: return "Claude"
        case .gemini: return "Gemini"
        case .nvidia: return "NVIDIA"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .openAI:    return .openAIAccent
        case .anthropic: return .anthropicAccent
        case .gemini:    return .geminiAccent
        case .nvidia:    return .nvidiaAccent
        }
    }

    var initials: String {
        switch self {
        case .openAI:    return "GPT"
        case .anthropic: return "ANT"
        case .gemini:    return "GEM"
        case .nvidia:    return "NVD"
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
        id: "openai/gpt-4o",
        name: "GPT-4o",
        provider: .openAI,
        contextWindow: 128_000,
        supportsStreaming: true,
        isPro: false
    )

    static let claude3Sonnet = AIModel(
        id: "anthropic/claude-3.5-sonnet",
        name: "Claude 3.5 Sonnet",
        provider: .anthropic,
        contextWindow: 200_000,
        supportsStreaming: true,
        isPro: false
    )

    static let geminiPro = AIModel(
        id: "google/gemini-1.5-pro",
        name: "Gemini 1.5 Pro",
        provider: .gemini,
        contextWindow: 1_000_000,
        supportsStreaming: true,
        isPro: false
    )
    
    static let nemotron = AIModel(
        id: "nvidia/nemotron-3-super-120b-a12b:free",
        name: "Nemotron-3 120B",
        provider: .nvidia,
        contextWindow: 262_144 ,
        supportsStreaming: true,
        isPro: false
    )

    static let allModels: [AIModel] = [.gpt4o, .claude3Sonnet, .geminiPro, .nemotron]
}
