import Foundation
import Combine

@MainActor
final class APIKeyManagementViewModel: ObservableObject {

    enum Feedback: Equatable {
        case saved
        case error(String)
    }

    @Published var draftKey: String = ""
    @Published var isRevealed: Bool = false
    @Published var hasStoredKey: Bool = false
    @Published var feedback: Feedback? = nil
    @Published var isVerifying: Bool = false

    private let useCase: ManageAPIKeyUseCaseProtocol
    private var saveTask: Task<Void, Never>?

    init(useCase: ManageAPIKeyUseCaseProtocol) {
        self.useCase = useCase
    }
    
    deinit {
        saveTask?.cancel()
    }

    func loadKeyStatus() {
        hasStoredKey = useCase.hasKey()
    }

    func save() {
        saveTask?.cancel()
        saveTask = Task {
            isVerifying = true
            feedback = nil
            do {
                try await useCase.saveKey(draftKey)
                if Task.isCancelled { return }
                hasStoredKey = true
                draftKey = ""
                isRevealed = false
                feedback = .saved
            } catch is CancellationError {
                return
            } catch {
                if Task.isCancelled { return }
                feedback = .error(error.localizedDescription)
                logError("Save API key failed: \(error.localizedDescription)")
            }
            if Task.isCancelled { return }
            isVerifying = false
        }
    }

    func delete() {
        do {
            try useCase.deleteKey()
            hasStoredKey = false
            draftKey = ""
            isRevealed = false
            feedback = nil
        } catch {
            feedback = .error(error.localizedDescription)
            logError("Delete API key failed: \(error.localizedDescription)")
        }
    }

    func clearFeedback() {
        feedback = nil
    }

    func toggleReveal() {
        isRevealed.toggle()
    }
}
