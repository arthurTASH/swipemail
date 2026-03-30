import Foundation

public enum SwipeAction: String, CaseIterable, Equatable, Sendable {
    case markRead
    case followUp
    case delete
    case spam

    public var analyticsLabel: String {
        rawValue
    }

    public func makeOperation(for message: GmailMessage) -> SwipeQueueOperation {
        SwipeQueueOperation(
            action: self,
            messageID: message.id,
            threadID: message.threadID,
            mutation: mutation
        )
    }

    var mutation: GmailMutation {
        switch self {
        case .markRead:
            return .modify(
                addLabelIDs: [],
                addLabelNames: [],
                removeLabelIDs: ["UNREAD"]
            )
        case .followUp:
            return .modify(
                addLabelIDs: [],
                addLabelNames: ["FOLLOW UP"],
                removeLabelIDs: ["UNREAD"]
            )
        case .delete:
            return .trash
        case .spam:
            return .spam
        }
    }
}

public struct SwipeQueueOperation: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let action: SwipeAction
    public let messageID: String
    public let threadID: String
    public let mutation: GmailMutation

    public init(
        id: UUID = UUID(),
        action: SwipeAction,
        messageID: String,
        threadID: String,
        mutation: GmailMutation
    ) {
        self.id = id
        self.action = action
        self.messageID = messageID
        self.threadID = threadID
        self.mutation = mutation
    }
}

public enum GmailMutation: Equatable, Sendable {
    case modify(
        addLabelIDs: [String],
        addLabelNames: [String],
        removeLabelIDs: [String]
    )
    case trash
    case spam
}
