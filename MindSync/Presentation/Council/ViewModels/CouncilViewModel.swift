import Foundation

@MainActor
final class CouncilViewModel: ObservableObject {

    // MARK: - Response model

    struct Response: Identifiable {
        let model: AIModel
        var content: String = ""
        var isStreaming: Bool = false
        var error: String? = nil
        var id: String { model.id }
    }

    // MARK: - Published state

    @Published private(set) var responses: [Response] = AIModel.allModels.map { Response(model: $0) }
    @Published private(set) var isStreaming: Bool = false
    @Published private(set) var prompt: String = ""
    @Published var inputText: String = ""

    // MARK: - Private

    private let useCase: SendCouncilMessageUseCaseProtocol
    private var streamingTasks: [Task<Void, Never>] = []

    init(useCase: SendCouncilMessageUseCaseProtocol) {
        self.useCase = useCase
    }

    // MARK: - Actions

    func send() {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !isStreaming else { return }

        inputText = ""
        prompt = content
        isStreaming = true
        responses = AIModel.allModels.map { Response(model: $0, isStreaming: true) }

        streamingTasks = AIModel.allModels.map { model in
            Task { await streamResponse(for: model, content: content) }
        }
    }

    func cancel() {
        streamingTasks.forEach { $0.cancel() }
        streamingTasks = []
        for i in responses.indices {
            responses[i].isStreaming = false
        }
        isStreaming = false
    }

    // MARK: - Private streaming

    private func streamResponse(for model: AIModel, content: String) async {
        do {
            let stream = useCase.stream(content: content, model: model)
            for try await delta in stream {
                guard let i = responses.firstIndex(where: { $0.model.id == model.id }) else { break }
                responses[i].content += delta
            }
        } catch is CancellationError {
            // user-initiated — no error shown
        } catch {
            if let i = responses.firstIndex(where: { $0.model.id == model.id }) {
                let message = (error as? AppError)?.errorDescription ?? error.localizedDescription
                responses[i].error = message
            }
            logError("Council streaming error [\(model.name)]: \(error.localizedDescription)")
        }

        if let i = responses.firstIndex(where: { $0.model.id == model.id }) {
            responses[i].isStreaming = false
        }

        if responses.allSatisfy({ !$0.isStreaming }) {
            isStreaming = false
        }
    }
}
