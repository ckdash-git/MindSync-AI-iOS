import Foundation

final class ChatSessionLocalRepository: ChatSessionRepositoryProtocol {

    private let baseURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        let fm = FileManager.default
        let appSupport = (try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fm.temporaryDirectory
        baseURL = appSupport.appendingPathComponent("ChatSessions", isDirectory: true)
        try? fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    func save(_ session: ChatSession) async throws {
        guard !session.messages.filter({ $0.role != .system }).isEmpty else { return }
        var toSave = session
        if toSave.title == "New Chat",
           let firstUserMessage = toSave.messages.first(where: { $0.role == .user }) {
            toSave.title = String(firstUserMessage.content.prefix(40))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        toSave.updatedAt = Date()
        let data = try encoder.encode(toSave)
        try data.write(to: fileURL(for: session.id), options: .atomic)
    }

    func loadAll() async throws -> [ChatSession] {
        let fm = FileManager.default
        let files = try fm.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil)
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(ChatSession.self, from: Data(contentsOf: $0)) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func delete(id: UUID) async throws {
        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func fileURL(for id: UUID) -> URL {
        baseURL.appendingPathComponent("\(id.uuidString).json")
    }
}
