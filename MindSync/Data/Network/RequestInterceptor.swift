import Foundation

protocol RequestInterceptorProtocol {
    func intercept(request: URLRequest) async throws -> URLRequest
    func intercept(response: HTTPURLResponse, data: Data) async throws
}

/// Default pass-through interceptor.
/// Replace with a logging or PII-masking interceptor for specific environments.
struct PassthroughInterceptor: RequestInterceptorProtocol {
    func intercept(request: URLRequest) async throws -> URLRequest { request }
    func intercept(response: HTTPURLResponse, data: Data) async throws {}
}
