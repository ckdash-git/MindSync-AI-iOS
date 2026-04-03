import SwiftUI

struct ContentView: View {

    private let container = DependencyContainer.shared

    var body: some View {
        TabView {
            ChatView(viewModel: container.makeChatViewModel())
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }

            CouncilView(viewModel: container.makeCouncilViewModel())
                .tabItem {
                    Label("Council", systemImage: "rectangle.3.group")
                }

            SessionHistoryView(
                viewModel: container.makeSessionHistoryViewModel(),
                makeChatViewModel: container.makeChatViewModel(session:)
            )
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }

            APIKeyManagementView(viewModel: container.makeAPIKeyManagementViewModel())
                .tabItem {
                    Label("API Keys", systemImage: "key.horizontal")
                }
        }
        .tint(Color.accentBrand)
    }
}
