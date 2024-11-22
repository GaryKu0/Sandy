import SwiftUI

struct AnimatedButton: View {
    let text: String
    let action: () -> Void
    var lightBackgroundColor: Color = .black
    var darkBackgroundColor: Color = .white
    var foregroundColor: Color = .white
    var cornerRadius: CGFloat = 300
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 12

    @State private var isSelected = false
    @State private var showCheck = false

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isSelected = true
                showCheck = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                action()
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSelected = false
                    showCheck = false
                }
            }
        }) {
            ZStack {
                Text(text)
                    .blur(radius: isSelected ? 3 : 0)
                    .opacity(isSelected ? 0.3 : 1)
                    .fontWeight(.bold)

                if showCheck {
                    Image(systemName: "checkmark")
                        .foregroundColor(colorScheme == .dark ? lightBackgroundColor : darkBackgroundColor)
                        .font(.system(size: 20, weight: .bold))
                        .scaleEffect(showCheck ? 1 : 0.8) // Adjust scaling when showing
                        .opacity(showCheck ? 1 : 0) // Adjust opacity to fade in and out
                        .animation(.easeInOut(duration: 0.3), value: showCheck)
                }
            }
            .frame(maxWidth: .infinity) // Extend to full width
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .foregroundColor(colorScheme == .dark ? lightBackgroundColor : darkBackgroundColor)
        .background(colorScheme == .dark ? darkBackgroundColor : lightBackgroundColor)
        .cornerRadius(cornerRadius)
    }
}
