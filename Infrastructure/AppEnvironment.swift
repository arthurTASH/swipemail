import Foundation

public struct AppEnvironment {
    public struct GmailAPI {
        public let baseURL: URL
        public let scopes: [String]
    }

    public let oauthClientID: String
    public let oauthRedirectURI: String
    public let gmailAPI: GmailAPI

    public static let current = try! AppEnvironment(bundle: .main)

    init(bundle: Bundle) throws {
        oauthClientID = try bundle.requiredString(for: "SwipeMailOAuthClientID")
        oauthRedirectURI = try bundle.requiredString(for: "SwipeMailOAuthRedirectURI")

        let baseURLString = try bundle.requiredString(for: "SwipeMailGmailAPIBaseURL")
        guard let baseURL = URL(string: baseURLString) else {
            throw AppEnvironmentError.invalidURL(key: "SwipeMailGmailAPIBaseURL", value: baseURLString)
        }

        gmailAPI = GmailAPI(
            baseURL: baseURL,
            scopes: try [
                bundle.requiredString(for: "SwipeMailGmailReadonlyScope"),
                bundle.requiredString(for: "SwipeMailGmailModifyScope"),
                bundle.requiredString(for: "SwipeMailGmailLabelsScope"),
            ]
        )
    }
}

enum AppEnvironmentError: LocalizedError {
    case missingValue(key: String)
    case invalidURL(key: String, value: String)

    var errorDescription: String? {
        switch self {
        case let .missingValue(key):
            return "Missing required app environment value for \(key)."
        case let .invalidURL(key, value):
            return "Invalid URL for \(key): \(value)"
        }
    }
}

private extension Bundle {
    func requiredString(for key: String) throws -> String {
        guard let value = object(forInfoDictionaryKey: key) as? String else {
            throw AppEnvironmentError.missingValue(key: key)
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            throw AppEnvironmentError.missingValue(key: key)
        }

        return trimmedValue
    }
}
