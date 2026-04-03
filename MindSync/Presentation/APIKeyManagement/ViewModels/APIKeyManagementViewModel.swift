import Foundation

@MainActor
final class APIKeyManagementViewModel: ObservableObject {

    struct ProviderState: Identifiable {
        let provider: AIProvider
        var draftKey: String = ""
        var isRevealed: Bool = false
        var hasStoredKey: Bool = false
        var feedback: Feedback? = nil

        var id: String { provider.rawValue }

        enum Feedback: Equatable {
            case saved
            case error(String)
        }
    }

    @Published var providerStates: [ProviderState] = [.openAI, .anthropic, .gemini]
        .map { ProviderState(provider: $0) }

    private let useCase: ManageAPIKeyUseCaseProtocol

    init(useCase: ManageAPIKeyUseCaseProtocol) {
        self.useCase = useCase
    }

    func loadKeyStatuses() {
        for i in providerStates.indices {
            providerStates[i].hasStoredKey = useCase.hasKey(for: providerStates[i].provider)
        }
    }

    func save(for provider: AIProvider) {
        guard let i = providerStates.firstIndex(where: { $0.provider == provider }) else { return }
        do {
            try useCase.saveKey(providerStates[i].draftKey, for: provider)
            providerStates[i].hasStoredKey = true
            providerStates[i].draftKey = ""
            providerStates[i].isRevealed = false
            providerStates[i].feedback = .saved
        } catch {
            providerStates[i].feedback = .error(error.localizedDescription)
            logError("Save API key failed for \(provider.displayName): \(error.localizedDescription)")
        }
    }

    func delete(for provider: AIProvider) {
        guard let i = providerStates.firstIndex(where: { $0.provider == provider }) else { return }
        do {
            try useCase.deleteKey(for: provider)
            providerStates[i].hasStoredKey = false
            providerStates[i].draftKey = ""
            providerStates[i].isRevealed = false
            providerStates[i].feedback = nil
        } catch {
            providerStates[i].feedback = .error(error.localizedDescription)
            logError("Delete API key failed for \(provider.displayName): \(error.localizedDescription)")
        }
    }

    func clearFeedback(for provider: AIProvider) {
        guard let i = providerStates.firstIndex(where: { $0.provider == provider }) else { return }
        providerStates[i].feedback = nil
    }

    func toggleReveal(for provider: AIProvider) {
        guard let i = providerStates.firstIndex(where: { $0.provider == provider }) else { return }
        providerStates[i].isRevealed.toggle()
    }
}
