import Foundation

protocol QueueService {
    func enqueue(_ action: SwipeAction, for messageID: String) async
}

struct InMemoryQueueService: QueueService {
    func enqueue(_ action: SwipeAction, for messageID: String) async {}
}
