import Foundation

protocol ChatSessionRepositoryProtocol {
    func save(_ session: ChatSession) async throws
    func loadAll() async throws -> [ChatSession]
    func delete(id: UUID) async throws
}
