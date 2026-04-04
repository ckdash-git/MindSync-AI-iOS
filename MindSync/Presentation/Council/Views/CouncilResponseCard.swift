import SwiftUI

struct CouncilResponseCard: View {

    let response: CouncilViewModel.Response

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            Divider()
            responseContent
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(spacing: 8) {
            providerIconView
            Text(response.model.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primaryText)
            Spacer()
            if response.isStreaming {
                TypingIndicatorView()
            }
        }
    }

    private var responseContent: some View {
        Group {
            if let error = response.error {
                Text(error)
                    .font(.body)
                    .foregroundStyle(.red)
            } else if response.content.isEmpty {
                Color.clear.frame(height: 20)
            } else {
                Text(response.content)
                    .font(.body)
                    .foregroundStyle(Color.primaryText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var providerIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(providerColor.opacity(0.15))
                .frame(width: 28, height: 28)
            Text(providerInitials)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(providerColor)
        }
    }

    // MARK: - Helpers

    private var providerColor: Color {
        switch response.model.provider {
        case .openAI:    return .openAIAccent
        case .anthropic: return .anthropicAccent
        case .gemini:    return .geminiAccent
        case .nvidia:    return .nvidiaAccent
        }
    }

    private var providerInitials: String {
        switch response.model.provider {
        case .openAI:    return "GPT"
        case .anthropic: return "ANT"
        case .gemini:    return "GEM"
        case .nvidia:    return "NVD"
        }
    }
}
