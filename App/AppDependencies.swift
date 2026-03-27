import Foundation

struct AppDependencies {
    let authService: AuthService
    let gmailService: GmailService
    let queueService: QueueService
    let syncEngine: SyncEngine
    let analyticsService: AnalyticsService
    let logger: AppLogger

    static func live() -> AppDependencies {
        let tokenStore = KeychainSessionTokenStore()
        let logger = OSAppLogger()
        let analyticsService = NoOpAnalyticsService()

        return AppDependencies(
            authService: DefaultAuthService(
                tokenStore: tokenStore,
                logger: logger,
                analyticsService: analyticsService
            ),
            gmailService: PlaceholderGmailService(),
            queueService: InMemoryQueueService(),
            syncEngine: PlaceholderSyncEngine(),
            analyticsService: analyticsService,
            logger: logger
        )
    }
}
