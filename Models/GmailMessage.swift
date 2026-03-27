import Foundation

public struct GmailMessage: Identifiable, Equatable, Sendable {
    public let id: String
    public let sender: String
    public let subject: String
    public let preview: String

    public init(id: String, sender: String, subject: String, preview: String) {
        self.id = id
        self.sender = sender
        self.subject = subject
        self.preview = preview
    }
}
