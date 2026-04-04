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
    @Published var isTTSEnabled: Bool = false

    // MARK: - Voice forwarding (backed by speechService)

    var isRecording: Bool { speechService.isRecording }
    var isSpeaking: Bool { speechService.isSpeaking }
    var isSpeechAvailable: Bool { speechService.isAvailable }

    // MARK: - Private

    private let sendMessageUseCase: SendMessageUseCaseProtocol
    private let sessionRepository: ChatSessionRepositoryProtocol
    private let speechService: SpeechServiceProtocol
    private var streamingTask: Task<Void, Never>?
    private var session: ChatSession
    private var cancellables = Set<AnyCancellable>()

    init(
        sendMessageUseCase: SendMessageUseCaseProtocol,
        sessionRepository: ChatSessionRepositoryProtocol,
        speechService: SpeechServiceProtocol,
        session: ChatSession = ChatSession()
    ) {
        self.sendMessageUseCase = sendMessageUseCase
        self.sessionRepository = sessionRepository
        self.speechService = speechService
        self.session = session
        self.messages = session.messages.filter { !$0.isStreaming }
        self.selectedModel = session.selectedModel

        speechService.statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Chat

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
                    if isTTSEnabled {
                        speechService.speak(messages[idx].content)
                    }
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
        speechService.stopSpeaking()
        if speechService.isRecording {
            speechService.stopRecording()
        }
        inputText = ""
        messages = []
        session = ChatSession(selectedModel: selectedModel)
    }

    func dismissError() {
        errorMessage = nil
    }

    // MARK: - Voice

    func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
            inputText = speechService.transcript
        } else {
            Task {
                if !speechService.isAvailable {
                    let granted = await speechService.requestPermissions()
                    guard granted else {
                        errorMessage = "Microphone or speech recognition access is required. Enable it in Settings."
                        return
                    }
                }
                do {
                    try speechService.startRecording()
                } catch {
                    errorMessage = error.localizedDescription
                    logError("Recording start failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func toggleTTS() {
        if isSpeaking {
            speechService.stopSpeaking()
        }
        isTTSEnabled.toggle()
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
