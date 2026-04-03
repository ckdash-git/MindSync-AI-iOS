import SwiftUI

struct CouncilView: View {

    @StateObject private var viewModel: CouncilViewModel

    init(viewModel: CouncilViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            councilHeader
            Divider()
            contentArea
            inputBar
        }
        .background(Color.surfaceBackground)
    }

    // MARK: - Header

    private var councilHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Council")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primaryText)
                Text("Compare all models side by side")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
            }
            Spacer()
            if viewModel.isStreaming {
                Button(action: viewModel.cancel) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.red)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.surfaceBackground)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isStreaming)
    }

    // MARK: - Content

    private var contentArea: some View {
        ScrollView {
            if viewModel.prompt.isEmpty {
                EmptyStateView(
                    title: "Ask all models at once",
                    subtitle: "Send one prompt and compare GPT-4o, Claude, and Gemini side by side.",
                    systemImage: "rectangle.3.group"
                )
                .padding(.top, 60)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    promptBubble
                    ForEach(viewModel.responses) { response in
                        CouncilResponseCard(response: response)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }

    private var promptBubble: some View {
        HStack {
            Spacer(minLength: 60)
            Text(viewModel.prompt)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.accentBrand)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.messageBubbleCornerRadius))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask all models…", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            actionButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.surfaceBackground)
    }

    private var actionButton: some View {
        Button {
            if viewModel.isStreaming {
                viewModel.cancel()
            } else {
                viewModel.send()
            }
        } label: {
            Image(systemName: viewModel.isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    viewModel.isStreaming
                        ? Color.red
                        : (viewModel.inputText.isEmpty ? Color.secondary : Color.accentBrand)
                )
        }
        .disabled(!viewModel.isStreaming && viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
