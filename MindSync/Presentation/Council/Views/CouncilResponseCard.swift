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
                .fill(response.model.provider.accentColor.opacity(0.15))
                .frame(width: 28, height: 28)
            Text(response.model.provider.initials)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(response.model.provider.accentColor)
        }
    }
}
