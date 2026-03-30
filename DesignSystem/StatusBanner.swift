import SwiftUI

struct StatusBanner: View {
    let state: StatusBannerState
    let dismissAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state.style.iconName)
                .font(.headline)

            Text(state.message)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let actionTitle = state.actionTitle, let action = state.action {
                Button(actionTitle, action: action)
                    .font(.caption.weight(.semibold))
            }

            Button("Dismiss", action: dismissAction)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(state.style.backgroundColor)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }
}

struct StatusBannerState: Identifiable, Equatable {
    enum Style: Equatable {
        case info
        case error

        var backgroundColor: Color {
            switch self {
            case .info:
                return .blue
            case .error:
                return .red
            }
        }

        var iconName: String {
            switch self {
            case .info:
                return "info.circle.fill"
            case .error:
                return "exclamationmark.triangle.fill"
            }
        }
    }

    let id = UUID()
    let message: String
    let style: Style
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        message: String,
        style: Style,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.message = message
        self.style = style
        self.actionTitle = actionTitle
        self.action = action
    }

    static func == (lhs: StatusBannerState, rhs: StatusBannerState) -> Bool {
        lhs.id == rhs.id &&
            lhs.message == rhs.message &&
            lhs.style == rhs.style &&
            lhs.actionTitle == rhs.actionTitle
    }
}
