import SwiftUI

enum SocialProvider {
    case google
    case github
    
    var title: String {
        switch self {
        case .google: return "Google"
        case .github: return "GitHub"
        }
    }
}

struct SocialAuthButton: View {
    var provider: SocialProvider
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if provider == .google {
                    Text("G")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "curlybraces")
                        .font(.system(size: 20, weight: .bold))
                }
                
                Text("Continue with \(provider.title)")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.surfaceBackground)
            .foregroundColor(Color.primaryText)
            .cornerRadius(AppConstants.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                    .stroke(Color.secondaryText.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.02), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.cardBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            SocialAuthButton(provider: .google, action: {})
            SocialAuthButton(provider: .github, action: {})
        }
        .padding()
    }
}
