import SwiftUI

struct MessageBubbleView: View {

    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if !isUser, let provider = message.provider {
                    Text(provider.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }

                bubbleContent
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }

    private var bubbleContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(message.content.isEmpty && message.isStreaming ? " " : message.content)
                .font(.body)
                .foregroundStyle(isUser ? Color.white : Color.primaryText)
                .textSelection(.enabled)

            if message.isStreaming {
                TypingIndicatorView()
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isUser ? Color.accentBrand : Color.assistantBubble)
        .clipShape(
            RoundedRectangle(cornerRadius: AppConstants.UI.messageBubbleCornerRadius)
        )
    }
}

struct TypingIndicatorView: View {

    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .frame(width: 5, height: 5)
                    .foregroundStyle(Color.secondary)
                    .scaleEffect(animating ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageBubbleView(message: ChatMessage(role: .user, content: "Hello, how are you?"))
        MessageBubbleView(message: ChatMessage(role: .assistant, content: "I'm doing well, thanks!", provider: .openAI, modelID: "gpt-4o"))
        MessageBubbleView(message: ChatMessage(role: .assistant, content: "", provider: .anthropic, modelID: "claude-3-5-sonnet-20241022", isStreaming: true))
    }
    .padding()
}
