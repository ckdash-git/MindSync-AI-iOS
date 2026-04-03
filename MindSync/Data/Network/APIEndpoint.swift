import Foundation

protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryParameters: [String: String]? { get }
    var body: Encodable? { get }
    var requiresStreaming: Bool { get }
}

extension APIEndpoint {
    var queryParameters: [String: String]? { nil }
    var body: Encodable? { nil }
    var requiresStreaming: Bool { false }

    func buildURLRequest() throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + path) else {
            throw AppError.custom(message: "Invalid endpoint configuration: \(baseURL + path)")
        }

        if let params = queryParameters {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else {
            throw AppError.custom(message: "Failed to construct URL for endpoint: \(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = requiresStreaming
            ? AppConstants.API.streamingTimeoutInterval
            : AppConstants.API.defaultTimeoutInterval

        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try AnyEncodable(body).encode(using: encoder)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}

/// Type-erasing wrapper that allows encoding `Encodable` existentials with `JSONEncoder`.
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: Encodable) {
        _encode = value.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }

    func encode(using encoder: JSONEncoder) throws -> Data {
        try encoder.encode(self)
    }
}
