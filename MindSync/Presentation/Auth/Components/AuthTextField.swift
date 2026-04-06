import SwiftUI

struct AuthTextField: View {
    var placeholder: String
    @Binding var text: String
    var iconName: String
    var isSecure: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 18))
                .foregroundColor(isFocused ? Color.accentBrand : Color.secondaryText)
                .frame(width: 24)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
            }
            .font(.system(.body, design: .rounded))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.surfaceBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                .stroke(isFocused ? Color.accentBrand : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        .animation(.easeInOut(duration: AppConstants.UI.animationDuration), value: isFocused)
    }
}

#Preview {
    ZStack {
        Color.cardBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            AuthTextField(placeholder: "Email Address", text: .constant(""), iconName: "envelope")
            AuthTextField(placeholder: "Password", text: .constant(""), iconName: "lock", isSecure: true)
        }
        .padding()
    }
}
