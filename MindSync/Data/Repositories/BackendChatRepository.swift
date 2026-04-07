import Foundation

final class BackendChatRepository: ChatRepositoryProtocol {

    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func streamMessage(
        _ message: ChatMessage,
        session: ChatSession,
        model: AIModel
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let requestBody = BackendChatRequestDTO(
                        message: message.content,
                        model: model.id
                    )
                    let endpoint = BackendChatEndpoint(requestBody: requestBody)
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
                    logError("Backend chat stream error: \(error.localizedDescription)")
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
        let requestBody = BackendChatRequestDTO(message: message.content, model: model.id)
        let endpoint = ChatNonStreamEndpoint(requestBody: requestBody)
        let response = try await networkManager.request(endpoint, responseType: ChatNonStreamResponseDTO.self)
        return ChatMessage(role: .assistant, content: response.data.response)
    }

    func saveSession(_ session: ChatSession) async throws {}
    func loadSessions() async throws -> [ChatSession] { [] }
    func deleteSession(_ sessionID: UUID) async throws {}
}
