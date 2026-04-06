import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = DependencyContainer.shared.makeAuthViewModel()
    @State private var showSignup: Bool = false

    var body: some View {
        ZStack {
            if showSignup {
                SignupView(showSignup: $showSignup, viewModel: viewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            } else {
                LoginView(showSignup: $showSignup, viewModel: viewModel)
                    .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: showSignup)
    }
}

#Preview {
    AuthView()
}
