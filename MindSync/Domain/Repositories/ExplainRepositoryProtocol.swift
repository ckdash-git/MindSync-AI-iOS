import Foundation

protocol ExplainRepositoryProtocol {
    func stream(message: String, model: String) -> AsyncThrowingStream<String, Error>
}
