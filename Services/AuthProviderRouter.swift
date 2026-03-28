import Foundation

protocol AuthProviderRouting {
    func provider(for emailAddress: String) -> AuthProvider
}

struct DefaultAuthProviderRouter: AuthProviderRouting {
    func provider(for emailAddress: String) -> AuthProvider {
        let normalizedEmail = emailAddress
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard let domain = normalizedEmail.split(separator: "@").last, normalizedEmail.contains("@") else {
            return .google
        }

        let domainString = String(domain)
        if domainString == "gmail.com" || domainString == "googlemail.com" {
            return .google
        }

        return .federated(domain: domainString)
    }
}
