import Foundation

struct AppDependencies {
    let authService: AuthService
    let gmailService: GmailService
    let queueService: QueueService
    let syncEngine: SyncEngine

    static func live() -> AppDependencies {
        let tokenStore = KeychainSessionTokenStore()

        return AppDependencies(
            authService: DefaultAuthService(tokenStore: tokenStore),
            gmailService: PlaceholderGmailService(),
            queueService: InMemoryQueueService(),
            syncEngine: PlaceholderSyncEngine()
        )
    }
}
