import Foundation

public enum InboxViewState: Equatable, Sendable {
    case loading
    case empty(message: String)
    case ready
    case error(AppError)
}
