import Foundation

protocol QueueService {
    func enqueue(_ operation: SwipeQueueOperation) async
    func nextOperation() async -> SwipeQueueOperation?
    func markCompleted(operationID: SwipeQueueOperation.ID) async
    func markFailed(operationID: SwipeQueueOperation.ID, error: AppError) async
    func failedOperations() async -> [QueuedSwipeOperation]
    func retryFailedOperations() async
}

struct QueuedSwipeOperation: Identifiable, Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case pending
        case failed(AppError)
    }

    let operation: SwipeQueueOperation
    var status: Status

    var id: SwipeQueueOperation.ID { operation.id }
}

actor InMemoryQueueService: QueueService {
    private var operations: [QueuedSwipeOperation] = []

    func enqueue(_ operation: SwipeQueueOperation) async {
        operations.append(
            QueuedSwipeOperation(
                operation: operation,
                status: .pending
            )
        )
    }

    func nextOperation() async -> SwipeQueueOperation? {
        operations.first(where: \.isPending)?.operation
    }

    func markCompleted(operationID: SwipeQueueOperation.ID) async {
        operations.removeAll { $0.id == operationID }
    }

    func markFailed(operationID: SwipeQueueOperation.ID, error: AppError) async {
        guard let index = operations.firstIndex(where: { $0.id == operationID }) else {
            return
        }

        operations[index].status = .failed(error)
    }

    func failedOperations() async -> [QueuedSwipeOperation] {
        operations.filter(\.isFailed)
    }

    func retryFailedOperations() async {
        for index in operations.indices {
            guard case .failed = operations[index].status else {
                continue
            }

            operations[index].status = .pending
        }
    }
}

private extension QueuedSwipeOperation {
    var isPending: Bool {
        if case .pending = status {
            return true
        }

        return false
    }

    var isFailed: Bool {
        if case .failed = status {
            return true
        }

        return false
    }
}
