import SwiftUI

struct InboxPlaceholderView: View {
    @GestureState private var dragOffset: CGSize = .zero
    @State private var committedSwipe: CommittedSwipe?
    @State private var isAnimatingDismissal = false

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
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.18), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 92, height: 92)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            }

            Text("You're all caught up! 🎉")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            HStack(spacing: 12) {
                Button("Check Again", action: retryAction)
                    .buttonStyle(.borderedProminent)

                Button("Exit for Now", action: signOutAction)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: 380)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 18, y: 8)
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
        if !messages.isEmpty {
            VStack(spacing: 16) {
                messageStack(messages: messages)
                actionRow

                Text("\(messages.count) unread primary message\(messages.count == 1 ? "" : "s") in queue")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 420)
        } else {
            emptyContent(message: "No unread primary messages remain in your queue right now.")
        }
    }

    private func messageStack(messages: [GmailMessage]) -> some View {
        ZStack(alignment: .top) {
            if let nextMessage = messages.dropFirst().first {
                stackGhostCard(nextMessage)
                    .offset(y: 18 + min(abs(dragOffset.height), 12))
                    .scaleEffect(0.97 + min(dragProgress, 0.05))
                    .opacity(0.88 + min(dragProgress * 0.18, 0.12))
                    .animation(.spring(response: 0.28, dampingFraction: 0.82), value: dragOffset)
            }

            VStack(spacing: 0) {
                if messages.count > 1 {
                    Text("Next up")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 10)
                }

                messageCard(messages[0], accent: .primary)
                    .offset(activeCardOffset)
                    .rotationEffect(cardRotationAngle)
                    .overlay(alignment: dragOverlayAlignment) {
                        if let dragDirection {
                            dragBadge(for: dragDirection)
                                .padding(20)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .contextMenu {
                        contextMenuActions
                    }
                    .gesture(cardDragGesture)
                    .animation(.spring(response: 0.24, dampingFraction: 0.78), value: activeCardOffset)
                    .animation(.spring(response: 0.24, dampingFraction: 0.78), value: committedSwipe?.action)
            }
        }
        .padding(.top, messages.count > 1 ? 6 : 0)
    }

    private var cardDragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($dragOffset) { value, state, _ in
                guard !isAnimatingDismissal else {
                    return
                }

                state = value.translation
            }
            .onEnded { value in
                guard !isAnimatingDismissal else {
                    return
                }

                guard let resolvedAction = resolvedAction(for: value.translation) else {
                    return
                }

                commitSwipe(resolvedAction)
            }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            actionButton(title: "Read", systemImage: "arrow.up", tint: .blue, action: .markRead)
            actionButton(title: "Delete", systemImage: "arrow.down", tint: .red, action: .delete)
            actionButton(title: "Follow Up", systemImage: "arrow.right", tint: .yellow, action: .followUp)
            actionButton(title: "Spam", systemImage: "arrow.left", tint: .orange, action: .spam)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var contextMenuActions: some View {
        Button {
            commitSwipe(.markRead)
        } label: {
            Label("Mark as Read", systemImage: "arrow.up")
        }

        Button {
            commitSwipe(.followUp)
        } label: {
            Label("Follow Up", systemImage: "arrow.right")
        }

        Button(role: .destructive) {
            commitSwipe(.delete)
        } label: {
            Label("Delete", systemImage: "arrow.down")
        }

        Button(role: .destructive) {
            commitSwipe(.spam)
        } label: {
            Label("Mark as Spam", systemImage: "arrow.left")
        }
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

    private func resolvedAction(for translation: CGSize) -> SwipeAction? {
        let horizontalMagnitude = abs(translation.width)
        let verticalMagnitude = abs(translation.height)

        guard max(horizontalMagnitude, verticalMagnitude) >= commitThreshold else {
            return nil
        }

        if horizontalMagnitude > verticalMagnitude {
            return translation.width > 0 ? .followUp : .spam
        }

        return translation.height < 0 ? .markRead : .delete
    }

    private var dragDirection: SwipeAction? {
        committedSwipe?.action ?? resolvedAction(for: dragOffset)
    }

    private var dragProgress: CGFloat {
        let dominantMagnitude = max(abs(dragOffset.width), abs(dragOffset.height))
        return min(dominantMagnitude / commitThreshold, 1)
    }

    private var activeCardOffset: CGSize {
        committedSwipe?.targetOffset ?? dragOffset
    }

    private var cardRotationAngle: Angle {
        Angle(degrees: Double(activeCardOffset.width / 18))
    }

    private var dragOverlayAlignment: Alignment {
        guard let dragDirection else {
            return .top
        }

        switch dragDirection {
        case .markRead:
            return .top
        case .followUp:
            return .trailing
        case .delete:
            return .bottom
        case .spam:
            return .leading
        }
    }

    private func messageCard(_ message: GmailMessage, accent: Color) -> some View {
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
                .stroke(accent.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 18, y: 8)
        .padding(.horizontal, 4)
    }

    private func dragBadge(for action: SwipeAction) -> some View {
        let style = dragBadgeStyle(for: action)

        return Label(style.title, systemImage: style.systemImage)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(style.color.opacity(0.92))
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .rotationEffect(style.rotation)
            .opacity(0.72 + dragProgress * 0.28)
    }

    private func dragBadgeStyle(for action: SwipeAction) -> (title: String, systemImage: String, color: Color, rotation: Angle) {
        switch action {
        case .markRead:
            return ("READ", "arrow.up", .blue, .degrees(0))
        case .followUp:
            return ("FOLLOW UP", "arrow.right", .yellow, .degrees(8))
        case .delete:
            return ("DELETE", "arrow.down", .red, .degrees(0))
        case .spam:
            return ("SPAM", "arrow.left", .orange, .degrees(-8))
        }
    }

    private func stackGhostCard(_ message: GmailMessage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message.sender)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(message.subject)
                .font(.headline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(message.preview)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .lineLimit(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, y: 4)
        .padding(.horizontal, 12)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func receivedDateLabel(for message: GmailMessage) -> String {
        guard let receivedAt = message.receivedAt else {
            return "Recent"
        }

        return receivedDateFormatter.localizedString(for: receivedAt, relativeTo: .now)
    }

    private func commitSwipe(_ action: SwipeAction) {
        isAnimatingDismissal = true
        committedSwipe = CommittedSwipe(action: action)

        Task {
            try? await Task.sleep(for: .milliseconds(220))

            await MainActor.run {
                actionHandler(action)
                committedSwipe = nil
                isAnimatingDismissal = false
            }
        }
    }
}

private let receivedDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter
}()

private let commitThreshold: CGFloat = 110

private struct CommittedSwipe {
    let action: SwipeAction

    var targetOffset: CGSize {
        switch action {
        case .markRead:
            return CGSize(width: 0, height: -540)
        case .followUp:
            return CGSize(width: 540, height: 40)
        case .delete:
            return CGSize(width: 0, height: 540)
        case .spam:
            return CGSize(width: -540, height: 40)
        }
    }
}
