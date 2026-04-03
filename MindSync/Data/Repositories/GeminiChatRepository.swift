import Foundation

final class GeminiChatRepository: ChatRepositoryProtocol {

    private let networkManager: NetworkManagerProtocol
    private let apiKeyRepository: APIKeyRepositoryProtocol

    init(
        networkManager: NetworkManagerProtocol,
        apiKeyRepository: APIKeyRepositoryProtocol
    ) {
        self.networkManager = networkManager
        self.apiKeyRepository = apiKeyRepository
    }

    func streamMessage(
        _ message: ChatMessage,
        session: ChatSession,
        model: AIModel
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let apiKey = try apiKeyRepository.getKey(for: .gemini)
                    let (systemInstruction, contents) = buildContents(from: session, newMessage: message)
                    let requestBody = GeminiChatRequestDTO(
                        contents: contents,
                        systemInstruction: systemInstruction
                    )
                    let endpoint = GeminiChatEndpoint(
                        apiKey: apiKey,
                        modelID: model.id,
                        requestBody: requestBody
                    )
                    let rawStream = networkManager.stream(endpoint)

                    for try await jsonToken in rawStream {
                        if let delta = SSEParser.extractToken(from: jsonToken) {
                            continuation.yield(delta)
                        }
                    }
                    continuation.finish()

                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    logError("Gemini stream error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func sendMessage(
        _ message: ChatMessage,
        session: ChatSession,
        model: AIModel
    ) async throws -> ChatMessage {
        throw AppError.custom(message: "Use streamMessage for real-time responses.")
    }

    func saveSession(_ session: ChatSession) async throws {}
    func loadSessions() async throws -> [ChatSession] { [] }
    func deleteSession(_ sessionID: UUID) async throws {}

    // MARK: - Private

    /// Returns (systemInstruction, contents).
    /// Gemini roles are "user" or "model" (not "assistant").
    /// System content is extracted into a separate systemInstruction field.
    private func buildContents(
        from session: ChatSession,
        newMessage: ChatMessage
    ) -> (systemInstruction: GeminiChatRequestDTO.Content?, contents: [GeminiChatRequestDTO.Content]) {
        let history = Array(
            session.messages
                .suffix(AppConstants.Chat.maxHistoryCount)
                .filter { !$0.isStreaming }
        )
        let allMessages = history.contains(where: { $0.id == newMessage.id })
            ? history
            : history + [newMessage]

        let systemText = allMessages
            .filter { $0.role == .system }
            .map(\.content)
            .joined(separator: "\n")

        let contents = allMessages
            .filter { $0.role != .system }
            .map { msg -> GeminiChatRequestDTO.Content in
                let geminiRole = msg.role == .assistant ? "model" : "user"
                return GeminiChatRequestDTO.Content(
                    role: geminiRole,
                    parts: [GeminiChatRequestDTO.Part(text: msg.content)]
                )
            }

        let systemInstruction = systemText.isEmpty ? nil : GeminiChatRequestDTO.Content(
            role: "user",
            parts: [GeminiChatRequestDTO.Part(text: systemText)]
        )

        return (systemInstruction, contents)
    }
}
