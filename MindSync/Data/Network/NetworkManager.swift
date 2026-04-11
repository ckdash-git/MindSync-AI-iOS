import Foundation

protocol NetworkManagerProtocol {
    func request<T: Decodable & Sendable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T
    func stream(_ endpoint: APIEndpoint) -> AsyncThrowingStream<String, Error>
}

final class NetworkManager: NetworkManagerProtocol {

    private let session: URLSession
    private let interceptor: RequestInterceptorProtocol
    private let decoder: JSONDecoder

    init(
        session: URLSession = .shared,
        interceptor: RequestInterceptorProtocol = PassthroughInterceptor()
    ) {
        self.session = session
        self.interceptor = interceptor
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func request<T: Decodable & Sendable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        var urlRequest = try endpoint.buildURLRequest()
        urlRequest = try await interceptor.intercept(request: urlRequest)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.custom(message: "Invalid server response.")
        }

        try await interceptor.intercept(response: httpResponse, data: data)

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let body = String(data: data, encoding: .utf8) {
                logDebug("HTTP \(httpResponse.statusCode) error — \(httpResponse.url?.path ?? ""): \(body)")
            }
            throw NetworkError.map(from: AppError.unknown, statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            logError("Decoding failed: \(error.localizedDescription)")
            throw AppError.decodingFailed
        }
    }

    func stream(_ endpoint: APIEndpoint) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var urlRequest = try endpoint.buildURLRequest()
                    urlRequest = try await self.interceptor.intercept(request: urlRequest)

                    let (bytes, response) = try await self.session.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: AppError.custom(message: "Invalid stream response."))
                        return
                    }

                    guard (200..<300).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: NetworkError.map(from: AppError.unknown, statusCode: httpResponse.statusCode))
                        return
                    }

                    for try await line in bytes.lines {
                        guard !line.isEmpty else { continue }
                        if let token = SSEParser.parse(line: line) {
                            continuation.yield(token)
                        }
                    }
                    continuation.finish()

                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    logError("Stream error: \(error.localizedDescription)")
                    continuation.finish(throwing: NetworkError.map(from: error))
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
