import Foundation

public struct AuthSession: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let idToken: String?
    public let accessTokenExpirationDate: Date?
    public let provider: AuthProvider

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        idToken: String? = nil,
        accessTokenExpirationDate: Date? = nil,
        provider: AuthProvider
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.accessTokenExpirationDate = accessTokenExpirationDate
        self.provider = provider
    }
}
