import Foundation

public enum AuthProvider: Codable, Equatable, Sendable {
    case google
    case federated(domain: String)

    public var analyticsLabel: String {
        switch self {
        case .google:
            return "google"
        case let .federated(domain):
            return "federated:\(domain)"
        }
    }
}
