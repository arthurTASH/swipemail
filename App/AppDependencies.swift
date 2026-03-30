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

        return AppDependencies(
            authService: DefaultAuthService(
                tokenStore: tokenStore,
                logger: logger,
                analyticsService: analyticsService,
                providerRouter: providerRouter,
                environment: environment,
                coordinator: coordinator
            ),
            gmailService: PlaceholderGmailService(),
            queueService: InMemoryQueueService(),
            syncEngine: PlaceholderSyncEngine(),
            analyticsService: analyticsService,
            logger: logger
        )
    }
}
