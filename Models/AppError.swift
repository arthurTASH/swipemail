import Foundation

public enum AppError: Error, Equatable, Sendable {
    case network(message: String)
    case auth(message: String)
    case unknown(message: String)

    public var message: String {
        switch self {
        case let .network(message), let .auth(message), let .unknown(message):
            return message
        }
    }

    public init(authFlowError: AuthFlowError) {
        switch authFlowError {
        case .unknown:
            self = .unknown(message: authFlowError.message)
        default:
            self = .auth(message: authFlowError.message)
        }
    }
}
