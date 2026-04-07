import Foundation

final class ExplainRepository: ExplainRepositoryProtocol {

    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func stream(message: String, model: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let requestBody = ExplainRequestDTO(message: message, model: model)
                    let endpoint = ExplainEndpoint(requestBody: requestBody)
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
                    logError("Explain stream error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
