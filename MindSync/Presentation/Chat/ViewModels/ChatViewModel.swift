import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {

    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isStreaming: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var inputText: String = ""
    @Published var selectedModel: AIModel = .gpt4o

    private let sendMessageUseCase: SendMessageUseCaseProtocol
    private var streamingTask: Task<Void, Never>?
    private var session: ChatSession

    init(sendMessageUseCase: SendMessageUseCaseProtocol) {
        self.sendMessageUseCase = sendMessageUseCase
        self.session = ChatSession()
    }

    func sendMessage() {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !isStreaming else { return }

        clearError()
        inputText = ""

        let userMessage = ChatMessage(role: .user, content: content)
        messages.append(userMessage)

        let assistantMessage = ChatMessage(
            role: .assistant,
            content: "",
            provider: selectedModel.provider,
            modelID: selectedModel.id,
            isStreaming: true
        )
        messages.append(assistantMessage)

        let assistantID = assistantMessage.id   // capture UUID, not fragile array index
        isStreaming = true

        session.messages.append(userMessage)

        streamingTask = Task {
            do {
                let stream = sendMessageUseCase.execute(
                    content: content,
                    session: session,
                    model: selectedModel
                )

                for try await delta in stream {
                    guard let idx = messages.firstIndex(where: { $0.id == assistantID }) else { break }
                    messages[idx].content += delta
                }

                if let idx = messages.firstIndex(where: { $0.id == assistantID }) {
                    messages[idx].isStreaming = false
                    session.messages.append(messages[idx])
                }

            } catch is CancellationError {
                if let idx = messages.firstIndex(where: { $0.id == assistantID }) {
                    messages[idx].isStreaming = false
                }
                // Cancellation is user-initiated — no error banner needed.

            } catch {
                if let idx = messages.firstIndex(where: { $0.id == assistantID }) {
                    messages[idx].isStreaming = false
                    messages[idx].content = "Something went wrong. Please try again."
                }
                showError(from: error)
                logError("Chat streaming error: \(error.localizedDescription)")
            }

            isStreaming = false
        }
    }

    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        if let lastIndex = messages.indices.last, messages[lastIndex].isStreaming {
            messages[lastIndex].isStreaming = false
        }
        isStreaming = false
    }

    func clearChat() {
        cancelStreaming()
        messages = []
        session = ChatSession(selectedModel: selectedModel)
    }

    func dismissError() {
        errorMessage = nil
    }

    private func showError(from error: Error) {
        if let appError = error as? AppError {
            errorMessage = appError.errorDescription
        } else {
            errorMessage = "An unexpected error occurred."
        }
    }

    private func clearError() {
        errorMessage = nil
    }
}
