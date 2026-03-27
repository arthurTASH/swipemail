import Foundation

protocol GmailService {
    func fetchUnreadPrimaryMessages() async throws -> [GmailMessage]
}

struct PlaceholderGmailService: GmailService {
    func fetchUnreadPrimaryMessages() async throws -> [GmailMessage] {
        []
    }
}
