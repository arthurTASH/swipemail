import Foundation

protocol SyncEngine {
    func syncPendingWork() async -> SyncExecutionResult
}

struct SyncExecutionResult: Sendable {
    var completedOperations = 0
    var failedOperations: [QueuedSwipeOperation] = []
}

struct DefaultSyncEngine: SyncEngine {
    private let queueService: QueueService
    private let gmailService: GmailService
    private let analyticsService: AnalyticsService
    private let logger: AppLogger

    init(
        queueService: QueueService,
        gmailService: GmailService,
        analyticsService: AnalyticsService,
        logger: AppLogger
    ) {
        self.queueService = queueService
        self.gmailService = gmailService
        self.analyticsService = analyticsService
        self.logger = logger
    }

    func syncPendingWork() async -> SyncExecutionResult {
        var result = SyncExecutionResult()

        while let operation = await queueService.nextOperation() {
            do {
                try await gmailService.perform(operation)
                await queueService.markCompleted(operationID: operation.id)
                result.completedOperations += 1
                analyticsService.track(
                    AnalyticsEvent(
                        name: "sync_operation_completed",
                        properties: [
                            "action": operation.action.analyticsLabel,
                            "messageID": operation.messageID,
                        ]
                    )
                )
                logger.info(
                    "Completed queued sync operation.",
                    metadata: [
                        "action": operation.action.analyticsLabel,
                        "messageID": operation.messageID,
                    ]
                )
            } catch let error as AppError {
                await queueService.markFailed(operationID: operation.id, error: error)
                analyticsService.track(
                    AnalyticsEvent(
                        name: "sync_operation_failed",
                        properties: [
                            "action": operation.action.analyticsLabel,
                            "messageID": operation.messageID,
                        ]
                    )
                )
                logger.error(
                    "Queued sync operation failed.",
                    metadata: [
                        "action": operation.action.analyticsLabel,
                        "messageID": operation.messageID,
                        "message": error.message,
                    ]
                )
                result.failedOperations = await queueService.failedOperations()
            } catch {
                let error = AppError.network(message: error.localizedDescription)
                await queueService.markFailed(operationID: operation.id, error: error)
                analyticsService.track(
                    AnalyticsEvent(
                        name: "sync_operation_failed",
                        properties: [
                            "action": operation.action.analyticsLabel,
                            "messageID": operation.messageID,
                        ]
                    )
                )
                logger.error(
                    "Queued sync operation failed.",
                    metadata: [
                        "action": operation.action.analyticsLabel,
                        "messageID": operation.messageID,
                        "message": error.message,
                    ]
                )
                result.failedOperations = await queueService.failedOperations()
            }
        }

        return result
    }
}
