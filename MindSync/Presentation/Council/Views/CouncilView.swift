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
                Text("Compare all models side by side")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
            }
            Spacer()
            if viewModel.isStreaming {
                Button(action: viewModel.cancel) {
                    Image(systemName: "stop.circle")
                        .font(.body)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.surfaceBackground)
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
                .frame(height: 300)
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
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.accentBrand)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask all models\u{2026}", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onSubmit {
                    if !viewModel.isStreaming {
                        viewModel.send()
                    }
                }

            Button(action: viewModel.send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? AnyShapeStyle(.tertiary)
                            : AnyShapeStyle(Color.accentBrand)
                    )
            }
            .disabled(
                viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || viewModel.isStreaming
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.surfaceBackground)
    }
}
