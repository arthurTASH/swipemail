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
}
