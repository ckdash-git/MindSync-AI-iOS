# MindSync AI — iOS

A production-grade iOS client for multi-provider AI chat. Chat with GPT-4o, Claude, and Gemini in a single app using your own API keys. Real-time streaming, a clean SwiftUI interface, and a strict Clean Architecture foundation.

---

## Features

- **Multi-provider chat** — OpenAI GPT-4o, Anthropic Claude 3.5 Sonnet, Google Gemini 1.5 Pro
- **Real-time streaming** — token-by-token response rendering via Server-Sent Events
- **BYOK (Bring Your Own Key)** — API keys stored securely in the iOS Keychain; never in plaintext
- **Provider switching** — swap models mid-session from the model selector
- **AI Council** *(coming soon)* — send one prompt to all providers in parallel and compare responses
- **Chat persistence** *(coming soon)* — full conversation history via SwiftData
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
| **Domain** | `AIModel`, `ChatMessage`, `ChatSession` entities; `ChatRepositoryProtocol`; `SendMessageUseCase`, `ManageAPIKeyUseCase` |
| **Data** | `NetworkManager` (async/await, SSE streaming); `OpenAIChatRepository`, `AnthropicChatRepository`, `GeminiChatRepository`; `ChatRepositoryRouter` |
| **Presentation** | `ChatViewModel` (`@MainActor`), `ChatView`, `MessageBubbleView`, shared UI components |
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
│   ├── Repositories/      # Protocol definitions
│   └── UseCases/          # SendMessageUseCase, ManageAPIKeyUseCase
├── Data/
│   ├── DTOs/              # Provider-specific request bodies
│   ├── Network/
│   │   ├── Endpoints/     # OpenAI, Anthropic, Gemini endpoint types
│   │   ├── NetworkManager.swift
│   │   ├── SSEParser.swift
│   │   └── RequestInterceptor.swift
│   └── Repositories/      # Concrete implementations + ChatRepositoryRouter
└── Presentation/
    ├── Chat/
    │   ├── Views/ChatView.swift
    │   └── ViewModels/ChatViewModel.swift
    └── Common/
        └── Components/    # MessageBubbleView, LoadingView, ErrorBannerView
```

---

## Requirements

| Requirement | Version |
|-------------|---------|
| iOS | 16.0+ |
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

### 3. Configure semantic colors

The app uses named colors from `Assets.xcassets`. Add the following color sets in Xcode's asset catalog:

| Name | Light | Dark |
|------|-------|------|
| `AccentBrand` | `#6C63FF` | `#6C63FF` |
| `CardBackground` | `#FFFFFF` | `#1C1C1E` |
| `SurfaceBackground` | `#F2F2F7` | `#000000` |
| `PrimaryText` | `#000000` | `#FFFFFF` |
| `SecondaryText` | `#6E6E73` | `#8E8E93` |
| `UserBubble` | `#6C63FF` | `#6C63FF` |
| `AssistantBubble` | `#F2F2F7` | `#2C2C2E` |

### 4. Add your API keys

Keys are stored in the iOS Keychain via `ManageAPIKeyUseCase`. You can set them programmatically during development or build a BYOK settings screen (coming in `feature/byok-management`):

```swift
let container = DependencyContainer.shared
try container.manageAPIKeyUseCase.saveKey("sk-...", for: .openAI)
try container.manageAPIKeyUseCase.saveKey("sk-ant-...", for: .anthropic)
try container.manageAPIKeyUseCase.saveKey("AIza...", for: .gemini)
```

### 5. Build and run

Select a simulator or device running iOS 16+ and press **Run** (`Cmd+R`).

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
| Chat UI polish + model selector | `feature/chat-module` | Planned |
| AI Council (parallel comparison) | `feature/ai-council` | Planned |
| Chat persistence (SwiftData) | `feature/local-storage` | Planned |
| BYOK key management UI | `feature/byok-management` | Planned |
| Voice interaction | `feature/voice` | Planned |
| Cross-device sync (PRO) | `feature/sync` | Planned |

---

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for branch naming, commit style, and PR guidelines.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
