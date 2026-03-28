import Foundation

public enum AuthFlowError: Error, Equatable, Sendable {
    case cancelled
    case configurationInvalid
    case unsupportedProvider(domain: String)
    case refreshFailed(message: String)
    case revocationFailed
    case persistenceFailed
    case presentationUnavailable
    case unknown(message: String)

    public var message: String {
        switch self {
        case .cancelled:
            return "Sign-in was cancelled."
        case .configurationInvalid:
            return "The OAuth configuration is invalid."
        case let .unsupportedProvider(domain):
            return "Federated sign-in for \(domain) is not implemented yet."
        case let .refreshFailed(message):
            return message
        case .revocationFailed:
            return "Signed out locally, but remote token revocation may not have completed."
        case .persistenceFailed:
            return "The authenticated session could not be saved securely."
        case .presentationUnavailable:
            return "Could not start sign-in because no presenting view controller was available."
        case let .unknown(message):
            return message
        }
    }
}
