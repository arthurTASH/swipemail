import Foundation

public struct GmailMessage: Identifiable, Equatable, Sendable {
    public let id: String
    public let threadID: String
    public let sender: String
    public let subject: String
    public let preview: String
    public let receivedAt: Date?
    public let labelIDs: [String]

    public init(
        id: String,
        threadID: String,
        sender: String,
        subject: String,
        preview: String,
        receivedAt: Date?,
        labelIDs: [String]
    ) {
        self.id = id
        self.threadID = threadID
        self.sender = sender
        self.subject = subject
        self.preview = preview
        self.receivedAt = receivedAt
        self.labelIDs = labelIDs
    }
}
