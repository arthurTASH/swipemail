import SwiftUI

struct InboxPlaceholderView: View {
    let state: InboxViewState
    let actionHandler: (SwipeAction) -> Void
    let retryAction: () -> Void
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
            loadingContent
        case let .empty(message):
            emptyContent(message: message)
        case let .ready(messages):
            readyContent(messages: messages)
        case let .error(error):
            errorContent(error: error)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)

            Text("Checking unread primary messages")
                .font(.headline)

            Text("SwipeMail is fetching the latest unread primary email from Gmail.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: 360)
    }

    private func emptyContent(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)

            Text("Inbox clear")
                .font(.headline)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            Button("Check Again", action: retryAction)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: 360)
    }

    private func errorContent(error: AppError) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34))
                .foregroundStyle(.red)

            Text("Couldn’t load Gmail")
                .font(.headline)

            Text(error.message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            Button("Try Again", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: 360)
    }

    @ViewBuilder
    private func readyContent(messages: [GmailMessage]) -> some View {
        if let firstMessage = messages.first {
            VStack(spacing: 16) {
                messageCard(firstMessage)
                actionRow

                Text("\(messages.count) unread primary message\(messages.count == 1 ? "" : "s") in queue")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 420)
        } else {
            Text("No unread primary messages right now.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            actionButton(title: "Read", systemImage: "arrow.up", tint: .blue, action: .markRead)
            actionButton(title: "Follow Up", systemImage: "arrow.down", tint: .yellow, action: .followUp)
            actionButton(title: "Delete", systemImage: "arrow.right", tint: .red, action: .delete)
            actionButton(title: "Spam", systemImage: "arrow.left", tint: .orange, action: .spam)
        }
        .frame(maxWidth: .infinity)
    }

    private func actionButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: SwipeAction
    ) -> some View {
        Button {
            actionHandler(action)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }

    private func messageCard(_ message: GmailMessage) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.sender)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(message.subject)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Text(receivedDateLabel(for: message))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(message.preview)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(5)

            HStack {
                Label("Primary", systemImage: "tray")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Swipe actions next")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 18, y: 8)
        .padding(.horizontal, 4)
    }

    private func receivedDateLabel(for message: GmailMessage) -> String {
        guard let receivedAt = message.receivedAt else {
            return "Recent"
        }

        return receivedDateFormatter.localizedString(for: receivedAt, relativeTo: .now)
    }
}

private let receivedDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter
}()
