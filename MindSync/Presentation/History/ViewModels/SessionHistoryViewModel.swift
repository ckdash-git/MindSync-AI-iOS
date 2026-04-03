import Foundation

@MainActor
final class SessionHistoryViewModel: ObservableObject {

    @Published private(set) var sessions: [ChatSession] = []
    @Published private(set) var isLoading: Bool = false

    private let sessionRepository: ChatSessionRepositoryProtocol

    init(sessionRepository: ChatSessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
    }

    func loadSessions() async {
        isLoading = true
        defer { isLoading = false }
        let repo = sessionRepository
        do {
            let loaded = try await Task.detached(priority: .userInitiated) {
                try await repo.loadAll()
            }.value
            sessions = loaded
        } catch {
            logError("SessionHistory load failed: \(error.localizedDescription)")
        }
    }

    func delete(id: UUID) async {
        let repo = sessionRepository
        do {
            try await Task.detached(priority: .userInitiated) {
                try await repo.delete(id: id)
            }.value
            sessions.removeAll { $0.id == id }
        } catch {
            logError("SessionHistory delete failed: \(error.localizedDescription)")
        }
    }
}
