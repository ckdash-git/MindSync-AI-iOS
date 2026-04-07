import SwiftUI

struct LoginView: View {
    @Binding var showSignup: Bool
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Welcome Back")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(Color.primaryText)

                        Text("Sign in to continue connecting with AI.")
                            .font(.subheadline)
                            .foregroundColor(Color.secondaryText)
                    }
                }
                .padding(.top, 40)

                // Form
                VStack(spacing: 16) {
                    AuthTextField(placeholder: "Email Address", text: $viewModel.email, iconName: "envelope")

                    VStack(alignment: .trailing, spacing: 8) {
                        AuthTextField(placeholder: "Password", text: $viewModel.password, iconName: "lock", isSecure: true)

                        Button("Forgot Password?") {
                            viewModel.sendPasswordReset()
                        }
                        .font(.footnote.weight(.medium))
                        .foregroundColor(viewModel.email.isEmpty ? Color.secondaryText : Color.accentBrand)
                        .disabled(viewModel.email.isEmpty)
                    }

                    Button {
                        viewModel.signIn()
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Sign In")
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
                    .padding(.top, 8)
                }

                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.secondaryText.opacity(0.2))
                        .frame(height: 1)
                    Text("Or")
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
                    Text("Don't have an account?")
                        .foregroundColor(Color.secondaryText)
                    Button("Sign up") {
                        withAnimation {
                            showSignup = true
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
            Button("OK", role: .cancel) { /* Dismiss alert. */ }
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred.")
        }
        .alert("Password Reset", isPresented: $viewModel.showResetAlert) {
            Button("OK", role: .cancel) { /* Dismiss alert. */ }
        } message: {
            Text("A password reset link has been sent to your email address.")
        }
    }
}

#Preview {
    LoginView(
        showSignup: .constant(false),
        viewModel: AuthViewModel(authUseCase: MockAuthUseCase(), authTokenRepository: MockAuthTokenRepository())
    )
}
