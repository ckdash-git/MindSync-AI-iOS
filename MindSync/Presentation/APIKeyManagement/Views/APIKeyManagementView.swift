import SwiftUI

struct APIKeyManagementView: View {

    @StateObject private var viewModel: APIKeyManagementViewModel

    init(viewModel: APIKeyManagementViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach($viewModel.providerStates) { $state in
                        ProviderKeyCard(state: $state) {
                            viewModel.save(for: state.provider)
                        } onDelete: {
                            viewModel.delete(for: state.provider)
                        } onToggleReveal: {
                            viewModel.toggleReveal(for: state.provider)
                        } onClearFeedback: {
                            viewModel.clearFeedback(for: state.provider)
                        }
                    }
                }
                .padding()
            }
            .background(Color.surfaceBackground)
            .navigationTitle("API Keys")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { viewModel.loadKeyStatuses() }
    }
}

// MARK: - Provider Key Card

private struct ProviderKeyCard: View {

    @Binding var state: APIKeyManagementViewModel.ProviderState
    let onSave: () -> Void
    let onDelete: () -> Void
    let onToggleReveal: () -> Void
    let onClearFeedback: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            providerHeader
            keyInputRow
            actionRow
            feedbackLabel
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .task(id: state.feedback) {
            guard state.feedback != nil else { return }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            onClearFeedback()
        }
    }

    // MARK: - Header

    private var providerHeader: some View {
        HStack(spacing: 10) {
            providerIcon
            Text(state.provider.displayName)
                .font(.headline)
                .foregroundStyle(Color.primaryText)
            Spacer()
            statusBadge
        }
    }

    private var providerIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(providerColor.opacity(0.15))
                .frame(width: 36, height: 36)
            Text(providerInitials)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(providerColor)
        }
    }

    private var statusBadge: some View {
        let isConfigured = state.hasStoredKey
        return HStack(spacing: 4) {
            Circle()
                .fill(isConfigured ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(isConfigured ? "Configured" : "Not set")
                .font(.caption.weight(.medium))
                .foregroundStyle(isConfigured ? Color.green : Color.orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill((isConfigured ? Color.green : Color.orange).opacity(0.1))
        )
    }

    // MARK: - Input

    private var keyInputRow: some View {
        HStack(spacing: 8) {
            Group {
                if state.isRevealed {
                    TextField(inputPlaceholder, text: $state.draftKey)
                } else {
                    SecureField(inputPlaceholder, text: $state.draftKey)
                }
            }
            .privacySensitive()
            .font(.system(.body, design: .monospaced))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button(action: onToggleReveal) {
                Image(systemName: state.isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(Color.secondaryText)
                    .frame(width: 36, height: 36)
            }
        }
    }

    // MARK: - Actions

    private var actionRow: some View {
        HStack(spacing: 10) {
            if state.hasStoredKey {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Button(action: onSave) {
                Label("Save Key", systemImage: "checkmark.shield")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentBrand)
            .disabled(state.draftKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Feedback

    @ViewBuilder
    private var feedbackLabel: some View {
        if let feedback = state.feedback {
            switch feedback {
            case .saved:
                Label("Key saved successfully", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            case .error(let message):
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Helpers

    private var inputPlaceholder: String {
        state.hasStoredKey ? "Enter new key to replace…" : "Enter API key…"
    }

    private var providerColor: Color {
        switch state.provider {
        case .openAI:    return .openAIAccent
        case .anthropic: return .anthropicAccent
        case .gemini:    return .geminiAccent
        }
    }

    private var providerInitials: String {
        switch state.provider {
        case .openAI:    return "GPT"
        case .anthropic: return "ANT"
        case .gemini:    return "GEM"
        }
    }
}
