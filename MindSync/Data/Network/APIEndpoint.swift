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
            throw AppError.networkUnavailable
        }

        if let params = queryParameters {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else {
            throw AppError.networkUnavailable
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
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}
