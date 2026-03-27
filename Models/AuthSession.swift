import Foundation

public struct AuthSession: Equatable, Sendable {
    public let accessToken: String

    public init(accessToken: String) {
        self.accessToken = accessToken
    }
}
