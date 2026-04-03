import Foundation

/// Central dependency container using protocol-based DI.
/// All dependencies are resolved here once and shared via environment or direct injection.
final class DependencyContainer {

    static let shared = DependencyContainer()

    // MARK: - Core
    lazy var keychainManager: KeychainManagerProtocol = KeychainManager()

    // MARK: - Network
    lazy var networkManager: NetworkManagerProtocol = NetworkManager()

    // MARK: - Repositories
    lazy var apiKeyRepository: APIKeyRepositoryProtocol = APIKeyRepository(
        keychainManager: keychainManager
    )

    lazy var chatRepository: ChatRepositoryProtocol = ChatRepositoryRouter(
        openAIRepository: OpenAIChatRepository(
            networkManager: networkManager,
            apiKeyRepository: apiKeyRepository
        ),
        anthropicRepository: AnthropicChatRepository(
            networkManager: networkManager,
            apiKeyRepository: apiKeyRepository
        ),
        geminiRepository: GeminiChatRepository(
            networkManager: networkManager,
            apiKeyRepository: apiKeyRepository
        )
    )

    // MARK: - Use Cases
    lazy var manageAPIKeyUseCase: ManageAPIKeyUseCaseProtocol = ManageAPIKeyUseCase(
        apiKeyRepository: apiKeyRepository
    )

    // MARK: - ViewModels
    func makeChatViewModel() -> ChatViewModel {
        let sendMessageUseCase = SendMessageUseCase(chatRepository: chatRepository)
        return ChatViewModel(sendMessageUseCase: sendMessageUseCase)
    }

    private init() {}
}
