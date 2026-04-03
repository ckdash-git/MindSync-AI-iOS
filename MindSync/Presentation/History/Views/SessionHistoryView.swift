import SwiftUI

struct SessionHistoryView: View {

    @StateObject private var viewModel: SessionHistoryViewModel
    private let makeChatViewModel: (ChatSession) -> ChatViewModel

    init(viewModel: SessionHistoryViewModel, makeChatViewModel: @escaping (ChatSession) -> ChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeChatViewModel = makeChatViewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading history…")
                } else if viewModel.sessions.isEmpty {
                    EmptyStateView(
                        title: "No saved chats",
                        subtitle: "Start a conversation and it will appear here automatically.",
                        systemImage: "clock.arrow.circlepath"
                    )
                } else {
                    sessionList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color.surfaceBackground)
        .task { await viewModel.loadSessions() }
    }

    // MARK: - List

    private var sessionList: some View {
        List {
            ForEach(viewModel.sessions) { session in
                NavigationLink {
                    ChatView(viewModel: makeChatViewModel(session))
                } label: {
                    SessionRowView(session: session)
                }
                .listRowBackground(Color.cardBackground)
            }
            .onDelete { indexSet in
                let idsToDelete = indexSet.map { viewModel.sessions[$0].id }
                Task {
                    for id in idsToDelete {
                        await viewModel.delete(id: id)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.surfaceBackground)
    }
}

// MARK: - Row

private struct SessionRowView: View {

    let session: ChatSession

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(session.title)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.primaryText)
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(session.selectedModel.name)
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)

                Text("·")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)

                Text("\(session.messages.count) messages")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)

                Spacer()

                Text(session.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding(.vertical, 2)
    }
}
