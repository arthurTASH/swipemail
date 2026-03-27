import SwiftUI

struct InboxPlaceholderView: View {
    let state: InboxViewState
    let signOutAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "tray.full")
                .font(.system(size: 40))
                .foregroundStyle(.tint)

            Text("Inbox Shell")
                .font(.title.bold())

            content

            Button("Clear Placeholder Session", action: signOutAction)
                .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView("Loading inbox state")
        case let .empty(message):
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
        case .ready:
            Text("Inbox content is ready.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
        case let .error(error):
            Text(error.message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.red)
                .padding(.horizontal, 24)
        }
    }
}
