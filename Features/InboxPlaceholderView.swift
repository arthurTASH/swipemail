import SwiftUI

struct InboxPlaceholderView: View {
    let signOutAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "tray.full")
                .font(.system(size: 40))
                .foregroundStyle(.tint)

            Text("Inbox Shell")
                .font(.title.bold())

            Text("A stored session token was found, so the app routed directly into the inbox placeholder.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            Button("Clear Placeholder Session", action: signOutAction)
                .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
    }
}
