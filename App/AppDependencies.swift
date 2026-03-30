import Foundation

struct AppDependencies {
    let authService: AuthService
    let gmailService: GmailService
    let queueService: QueueService
    let syncEngine: SyncEngine
    let analyticsService: AnalyticsService
    let logger: AppLogger

    @MainActor
    static func live() -> AppDependencies {
        let tokenStore = KeychainSessionTokenStore()
        let logger = OSAppLogger()
        let analyticsService = NoOpAnalyticsService()
        let providerRouter = DefaultAuthProviderRouter()
        let environment = AppEnvironment.current
        let coordinator = OAuthCoordinator()
        let queueService = InMemoryQueueService()
        let gmailService = DefaultGmailService(
            tokenStore: tokenStore,
            environment: environment,
            logger: logger,
            analyticsService: analyticsService
        )

        return AppDependencies(
            authService: DefaultAuthService(
                tokenStore: tokenStore,
                logger: logger,
                analyticsService: analyticsService,
                providerRouter: providerRouter,
                environment: environment,
                coordinator: coordinator
            ),
            gmailService: gmailService,
            queueService: queueService,
            syncEngine: DefaultSyncEngine(
                queueService: queueService,
                gmailService: gmailService,
                analyticsService: analyticsService,
                logger: logger
            ),
            analyticsService: analyticsService,
            logger: logger
        )
    }
}
