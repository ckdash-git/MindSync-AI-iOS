# Contributing to MindSync AI

## Branch Naming

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/<name>` | `feature/chat-module` |
| Bug fix | `fix/<name>` | `fix/stream-timeout` |
| Documentation | `docs/<name>` | `docs/api-reference` |
| Refactor | `refactor/<name>` | `refactor/network-layer` |

Always branch from `main`.

## Commit Style

Use the **imperative mood**. Describe what the commit does, not what you did.

```
Add streaming cancellation to ChatViewModel
Implement Anthropic message repository
Fix out-of-bounds crash in message index lookup
```

Do not use prefixes like `feat:`, `fix:`, `chore:`, or similar.

## Pull Requests

- One feature or fix per PR
- Reference the related issue in the PR description (`Closes #N`)
- Include a summary of changes, architecture decisions, and testing notes
- All new Swift files must be added to the Xcode target before opening a PR

## Architecture Rules

- No force unwraps
- No `print()` — use `logDebug` / `logInfo` / `logWarning` / `logError`
- All dependencies injected via protocol — no direct singleton access in ViewModels
- New features follow the existing layer structure: Core / Domain / Data / Presentation
- Every new UI color must use a semantic token from `Color+Extensions`

## Code Style

- Swift standard naming conventions
- `@MainActor` on all ViewModels
- `async/await` for all asynchronous code — no completion handlers
- Async streams use `continuation.onTermination` to prevent task leaks

## Security

- Never commit API keys, tokens, or credentials
- Sensitive data goes in Keychain via `KeychainManager`
- Sensitive values must be masked in logs (`[REDACTED]`)
