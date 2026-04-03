import SwiftUI

extension View {

    func cardStyle(cornerRadius: CGFloat = AppConstants.UI.cornerRadius) -> some View {
        self
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    func shimmerEffect(isActive: Bool) -> some View {
        self.redacted(reason: isActive ? .placeholder : [])
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
