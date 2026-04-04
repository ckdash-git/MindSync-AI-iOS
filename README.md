# MindSync AI — iOS

A production-grade iOS client for multi-provider AI chat. Chat with GPT-4o, Claude, and Gemini in a single app using your own API keys. Real-time streaming, a clean SwiftUI interface, and a strict Clean Architecture foundation.

---

## Features

- **Multi-provider chat** — OpenAI GPT-4o, Anthropic Claude 3.5 Sonnet, Google Gemini 1.5 Pro
- **Real-time streaming** — token-by-token response rendering via Server-Sent Events
- **BYOK (Bring Your Own Key)** — API keys stored securely in the iOS Keychain; managed via the in-app API Keys tab
- **Provider switching** — swap models mid-session from the model selector
- **AI Council** — send one prompt to all providers in parallel and compare responses side-by-side
- **Chat history** — full conversation persistence via JSON file storage; browsable session history
- **Voice interaction** *(coming soon)*
- **Cross-device sync** *(coming soon, PRO)*

---

## Architecture

MindSync AI is built on **Clean Architecture + MVVM** with strict layer separation and protocol-based dependency injection.

```
┌─────────────────────────────────────────────┐
│              Presentation Layer              │
│         Views (SwiftUI) + ViewModels         │
└───────────────────┬─────────────────────────┘
                    │ protocol calls
┌───────────────────▼─────────────────────────┐
│               Domain Layer                   │
│        Entities · UseCases · Protocols       │
└───────────────────┬─────────────────────────┘
                    │ protocol implementations
┌───────────────────▼─────────────────────────┐
│                Data Layer                    │
│   Network · Repositories · DTOs · Storage   │
└─────────────────────────────────────────────┘
```

| Layer | Contents |
|-------|----------|
| **Core** | Logger, AppError, KeychainManager, AppConstants, SwiftUI extensions |
| **Domain** | `AIModel`, `ChatMessage`, `ChatSession` entities; `ChatRepositoryProtocol`, `ChatSessionRepositoryProtocol`; `SendMessageUseCase`, `SendCouncilMessageUseCase`, `ManageAPIKeyUseCase` |
| **Data** | `NetworkManager` (async/await, SSE streaming); `OpenAIChatRepository`, `AnthropicChatRepository`, `GeminiChatRepository`, `ChatRepositoryRouter`; `ChatSessionLocalRepository` (JSON file storage) |
| **Presentation** | `ChatViewModel` + `ChatView`; `CouncilViewModel` + `CouncilView`; `SessionHistoryViewModel` + `SessionHistoryView`; `APIKeyManagementViewModel` + `APIKeyManagementView`; shared UI components |
| **Application** | `DependencyContainer` — single wiring point for all dependencies |

---

## Project Structure

```
MindSync/
├── Application/
│   └── DependencyContainer.swift
├── Core/
│   ├── Constants/AppConstants.swift
│   ├── Errors/AppError.swift
│   ├── Extensions/
│   ├── Logger/Logger.swift
│   └── Security/KeychainManager.swift
├── Domain/
│   ├── Entities/          # AIModel, ChatMessage, ChatSession
│   ├── Repositories/      # ChatRepositoryProtocol, ChatSessionRepositoryProtocol
│   └── UseCases/          # SendMessageUseCase, SendCouncilMessageUseCase, ManageAPIKeyUseCase
├── Data/
│   ├── DTOs/              # Provider-specific request bodies
│   ├── Network/
│   │   ├── Endpoints/     # OpenAI, Anthropic, Gemini endpoint types
│   │   ├── NetworkManager.swift
│   │   ├── SSEParser.swift
│   │   └── RequestInterceptor.swift
│   └── Repositories/      # Concrete implementations, ChatRepositoryRouter, ChatSessionLocalRepository
└── Presentation/
    ├── Chat/
    │   ├── Views/ChatView.swift
    │   └── ViewModels/ChatViewModel.swift
    ├── Council/
    │   ├── Views/CouncilView.swift + CouncilResponseCard.swift
    │   └── ViewModels/CouncilViewModel.swift
    ├── History/
    │   ├── Views/SessionHistoryView.swift
    │   └── ViewModels/SessionHistoryViewModel.swift
    ├── APIKeyManagement/
    │   ├── Views/APIKeyManagementView.swift
    │   └── ViewModels/APIKeyManagementViewModel.swift
    └── Common/
        └── Components/    # MessageBubbleView, LoadingView, ErrorBannerView, EmptyStateView, TypingIndicatorView
```

---

## Requirements

| Requirement | Version |
|-------------|---------|
| iOS | 18.6+ |
| Xcode | 15.0+ |
| Swift | 5.9+ |

No third-party dependencies. Pure URLSession, SwiftUI, and os.log.

---

## Getting Started

### 1. Clone and open

```bash
git clone https://github.com/ckdash-git/MindSync-AI-iOS.git
cd MindSync-AI-iOS
open MindSync.xcodeproj
```

### 2. Add new source files to Xcode

Files created outside Xcode must be registered manually. In Xcode's Project Navigator, drag any new folders under `MindSync/` into the target. Make sure **Add to target: MindSync** is checked.

### 3. Build and run

Select a simulator or device running iOS 18.6+ and press **Run** (`Cmd+R`).

### 4. Add your API keys

Open the **API Keys** tab in the app and enter keys for each provider. Keys are stored securely in the iOS Keychain and never leave the device.

| Provider | Where to get a key |
|----------|--------------------|
| OpenAI | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| Anthropic | [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) |
| Google Gemini | [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey) |

---

## Provider API Details

| Provider | Auth | Streaming |
|----------|------|-----------|
| OpenAI | `Authorization: Bearer {key}` | `data: {...}` SSE, `[DONE]` sentinel |
| Anthropic | `x-api-key: {key}` + `anthropic-version: 2023-06-01` | SSE with `event:` + `data:` lines |
| Gemini | `key` query parameter + `alt=sse` | `data: {...}` SSE per candidate |

---

## Roadmap

| Feature | Branch | Status |
|---------|--------|--------|
| Project setup + base architecture | `feature/project-setup` | Merged |
| OpenAI, Anthropic, Gemini streaming | `feature/networking-layer` | Merged |
| Chat UI polish + model selector | `feature/chat-module` | Merged |
| AI Council (parallel comparison) | `feature/ai-council` | Merged |
| Chat persistence (JSON storage) | `feature/local-storage` | Merged |
| BYOK key management UI | `feature/byok-management` | Merged |
| Voice interaction | `feature/voice` | Planned |
| Cross-device sync (PRO) | `feature/sync` | Planned |

---

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for branch naming, commit style, and PR guidelines.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
