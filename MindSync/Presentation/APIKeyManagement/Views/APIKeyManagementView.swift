import SwiftUI

struct APIKeyManagementView: View {

    private static let openRouterKeysURL = URL(string: "https://openrouter.ai/keys")

    @StateObject private var viewModel: APIKeyManagementViewModel

    init(viewModel: APIKeyManagementViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    Text("Enter an OpenRouter API key to power all models in MindSync.")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    keyCard
                    
                    if let openRouterURL = Self.openRouterKeysURL {
                        Link(destination: openRouterURL) {
                            HStack(spacing: 6) {
                                Text("Get OpenRouter Key")
                                Image(systemName: "arrow.up.right.square")
                            }
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.accentBrand)
                        }
                    }
                }
                .padding()
            }
            .background(Color.surfaceBackground)
            .navigationTitle("API Keys")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { viewModel.loadKeyStatus() }
    }

    // MARK: - Key Card

    private var keyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            keyInputRow
            actionRow
            feedbackLabel
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .task(id: viewModel.feedback) {
            guard viewModel.feedback != nil else { return }
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                viewModel.clearFeedback()
            } catch {
                return
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentBrand.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "key.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.accentBrand)
            }
            
            Text("OpenRouter API Key")
                .font(.headline)
                .foregroundStyle(Color.primaryText)
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(viewModel.hasStoredKey ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
                Text(viewModel.hasStoredKey ? "Configured" : "Not set")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(viewModel.hasStoredKey ? Color.green : Color.orange)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill((viewModel.hasStoredKey ? Color.green : Color.orange).opacity(0.1))
            )
        }
    }

    // MARK: - Input

    private var keyInputRow: some View {
        HStack(spacing: 8) {
            Group {
                if viewModel.isRevealed {
                    TextField(viewModel.hasStoredKey ? "Enter new key to replace…" : "Enter API key…", text: $viewModel.draftKey)
                } else {
                    SecureField(viewModel.hasStoredKey ? "Enter new key to replace…" : "Enter API key…", text: $viewModel.draftKey)
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

            Button(action: { viewModel.toggleReveal() }) {
                Image(systemName: viewModel.isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(Color.secondaryText)
                    .frame(width: 36, height: 36)
            }
        }
    }

    // MARK: - Actions

    private var actionRow: some View {
        HStack(spacing: 10) {
            if viewModel.hasStoredKey {
                Button(role: .destructive, action: { viewModel.delete() }) {
                    Label("Delete", systemImage: "trash")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(viewModel.isVerifying)
            }

            Button(action: { viewModel.save() }) {
                HStack {
                    if viewModel.isVerifying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Label("Verify & Save", systemImage: "checkmark.shield")
                    }
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentBrand)
            .disabled(viewModel.draftKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isVerifying)
        }
    }

    // MARK: - Feedback

    @ViewBuilder
    private var feedbackLabel: some View {
        if let feedback = viewModel.feedback {
            switch feedback {
            case .saved:
                Label("Key verified and saved", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            case .error(let message):
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.red)
            }
        }
    }
}
