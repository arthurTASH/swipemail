import SwiftUI

struct OnboardingView: View {
    let connectAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("SwipeMail")
                .font(.largeTitle.bold())

            Text("Connect your Gmail account to start processing unread messages one card at a time.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            Button("Connect Gmail Placeholder", action: connectAction)
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}
