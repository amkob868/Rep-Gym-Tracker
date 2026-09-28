import SwiftUI

/// A small, dismissible "coach" speech bubble that surfaces an AI-generated
/// insight about the user's workout history on the Home screen.
struct InsightBubbleView: View {
    let message: String
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ForgeTheme.accentBulk)

            VStack(alignment: .leading, spacing: 3) {
                Text("COACH")
                    .font(ForgeTheme.nunito(9, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(ForgeTheme.textMuted)
                Text(message)
                    .font(ForgeTheme.nunito(14, weight: .semibold))
                    .foregroundColor(ForgeTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ForgeTheme.textMuted)
                    .padding(6)
                    .contentShape(Rectangle())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ForgeTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ForgeTheme.accentBulk.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
        )
    }
}

#Preview {
    ZStack {
        ForgeTheme.background.ignoresSafeArea()
        InsightBubbleView(
            message: "Great progress on shoulders! You went from 95 to 115 lb in 3 weeks. Congrats! 🎉",
            onDismiss: {}
        )
        .padding()
    }
}
