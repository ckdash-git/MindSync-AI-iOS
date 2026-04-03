import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {

    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isStreaming: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var inputText: String = ""
    @Published var selectedModel: AIModel = .gpt4o {
        didSet { session.selectedModel = selectedModel }
    }

    private let sendMessageUseCase: SendMessageUseCaseProtocol
    private let sessionRepository: ChatSessionRepositoryProtocol
    private var streamingTask: Task<Void, Never>?
    private var session: ChatSession

    init(
        sendMessageUseCase: SendMessageUseCaseProtocol,
        sessionRepository: ChatSessionRepositoryProtocol,
        session: ChatSession = ChatSession()
    ) {
        self.sendMessageUseCase = sendMessageUseCase
        self.sessionRepository = sessionRepository
        self.session = session
        self.messages = session.messages.filter { !$0.isStreaming }
        self.selectedModel = session.selectedModel
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

        let assistantID = assistantMessage.id
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

                persistSession()

            } catch is CancellationError {
                if let idx = messages.firstIndex(where: { $0.id == assistantID }) {
                    messages[idx].isStreaming = false
                }

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

    // MARK: - Private

    private func persistSession() {
        let snapshot = session
        let repo = sessionRepository
        Task.detached(priority: .utility) {
            do {
                try await repo.save(snapshot)
            } catch {
                logError("Session persist failed: \(error.localizedDescription)")
            }
        }
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
