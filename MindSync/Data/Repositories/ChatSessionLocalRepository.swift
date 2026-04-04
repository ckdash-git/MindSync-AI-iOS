import Foundation

actor ChatSessionLocalRepository: ChatSessionRepositoryProtocol {

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

        let preferred = appSupport.appendingPathComponent("ChatSessions", isDirectory: true)
        do {
            try fm.createDirectory(at: preferred, withIntermediateDirectories: true)
            baseURL = preferred
        } catch {
            let fallback = fm.temporaryDirectory.appendingPathComponent("ChatSessions", isDirectory: true)
            try? fm.createDirectory(at: fallback, withIntermediateDirectories: true)
            baseURL = fallback
            logError("ChatSessions directory creation failed, using temp fallback: \(error.localizedDescription)")
        }
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
        var sessions: [ChatSession] = []
        for fileURL in files where fileURL.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: fileURL)
                sessions.append(try decoder.decode(ChatSession.self, from: data))
            } catch {
                let name = fileURL.lastPathComponent
                let desc = error.localizedDescription
                logError("Failed to decode session at \(name): \(desc)")
            }
        }
        return sessions.sorted { $0.updatedAt > $1.updatedAt }
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
