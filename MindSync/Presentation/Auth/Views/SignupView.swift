import SwiftUI

struct SignupView: View {
    @Binding var showSignup: Bool
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Create an Account")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(Color.primaryText)

                        Text("Join MindSync to power your AI thoughts.")
                            .font(.subheadline)
                            .foregroundColor(Color.secondaryText)
                    }
                }
                .padding(.top, 40)

                // Form
                VStack(spacing: 16) {
                    AuthTextField(placeholder: "Full Name", text: $viewModel.fullName, iconName: "person")
                    AuthTextField(placeholder: "Email Address", text: $viewModel.email, iconName: "envelope")
                    AuthTextField(placeholder: "Password", text: $viewModel.password, iconName: "lock", isSecure: true)

                    Button {
                        viewModel.signUp()
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Sign Up")
                                .font(.headline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.isLoading ? Color.accentBrand.opacity(0.6) : Color.accentBrand)
                        .foregroundColor(.white)
                        .cornerRadius(AppConstants.UI.cornerRadius)
                        .shadow(color: Color.accentBrand.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.top, 16)
                }

                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.secondaryText.opacity(0.2))
                        .frame(height: 1)
                    Text("Or sign up with")
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                        .padding(.horizontal, 8)
                    Rectangle()
                        .fill(Color.secondaryText.opacity(0.2))
                        .frame(height: 1)
                }

                // Social Actions
                VStack(spacing: 16) {
                    SocialAuthButton(provider: .google, action: { viewModel.signInWithGoogle() })
                    SocialAuthButton(provider: .github, action: { viewModel.signInWithGitHub() })
                }

                Spacer(minLength: 40)

                // Footer
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(Color.secondaryText)
                    Button("Log in") {
                        withAnimation {
                            showSignup = false
                        }
                    }
                    .foregroundColor(Color.accentBrand)
                    .fontWeight(.semibold)
                }
                .font(.subheadline)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.cardBackground.ignoresSafeArea())
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred.")
        }
    }
}

#Preview {
    SignupView(
        showSignup: .constant(true),
        viewModel: AuthViewModel(authUseCase: MockAuthUseCase(), authTokenRepository: MockAuthTokenRepository())
    )
}
