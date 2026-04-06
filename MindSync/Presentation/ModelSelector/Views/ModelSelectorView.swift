import SwiftUI

struct ModelSelectorView: View {

    @Binding var selectedModel: AIModel
    @Environment(\.dismiss) private var dismiss

    private let models: [AIModel] = AIModel.allModels

    var body: some View {
        NavigationStack {
            List(models) { model in
                ModelRowView(model: model, isSelected: model == selectedModel) {
                    selectedModel = model
                    dismiss()
                }
                .listRowBackground(Color.cardBackground)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.surfaceBackground)
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.accentBrand)
                }
            }
        }
    }
}

// MARK: - Row

private struct ModelRowView: View {

    let model: AIModel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                providerIconView
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.primaryText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentBrand)
                        .font(.system(size: 20))
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Private

    private var providerIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(model.provider.accentColor.opacity(0.15))
            Text(model.provider.initials)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(model.provider.accentColor)
        }
    }

    private var formattedContextWindow: String {
        let ctx = model.contextWindow
        if ctx >= 1_000_000 {
            return "\(ctx / 1_000_000)M"
        } else if ctx >= 1_000 {
            return "\(ctx / 1_000)K"
        } else {
            return "\(ctx)"
        }
    }

    private var subtitle: String {
        return "\(formattedContextWindow) ctx · \(model.provider.displayName)"
    }
}
