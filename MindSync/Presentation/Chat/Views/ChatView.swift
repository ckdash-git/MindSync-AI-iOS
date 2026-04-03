import SwiftUI

struct ChatView: View {

    @StateObject private var viewModel: ChatViewModel
    @State private var showModelSelector = false

    init(viewModel: ChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            Divider()
            messageList
            if let error = viewModel.errorMessage {
                ErrorBannerView(message: error, onDismiss: viewModel.dismissError)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            inputBar
        }
        .background(Color.surfaceBackground)
        .animation(.easeInOut(duration: AppConstants.UI.animationDuration), value: viewModel.errorMessage)
        .sheet(isPresented: $showModelSelector) {
            ModelSelectorView(selectedModel: $viewModel.selectedModel)
                .presentationDetents([.medium])
        }
    }

    private var chatHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MindSync AI")
                    .font(.headline)
                    .fontWeight(.semibold)
                Button(action: { showModelSelector = true }) {
                    HStack(spacing: 3) {
                        Text(viewModel.selectedModel.name)
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(Color.accentBrand)
                }
            }
            Spacer()
            Button(action: viewModel.clearChat) {
                Image(systemName: "square.and.pencil")
                    .font(.body)
            }
            .disabled(viewModel.isStreaming)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.surfaceBackground)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        EmptyStateView(
                            title: "Start a conversation",
                            subtitle: "Ask anything. Choose your AI model above.",
                            systemImage: "bubble.left.and.bubble.right"
                        )
                        .frame(height: 300)
                    } else {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .padding(.horizontal, 16)
                                .id(message.id)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .onValueChange(of: viewModel.messages.count) {
                if let lastID = viewModel.messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onSubmit {
                    if !viewModel.isStreaming {
                        viewModel.sendMessage()
                    }
                }

            Group {
                if viewModel.isStreaming {
                    Button(action: viewModel.cancelStreaming) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.red)
                    }
                } else {
                    Button(action: viewModel.sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.accentBrand)
                            .opacity(viewModel.inputText.isEmpty ? 0.3 : 1.0)
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.isStreaming)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.surfaceBackground)
    }
}
