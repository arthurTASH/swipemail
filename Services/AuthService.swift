import Foundation

protocol AuthService {
    func loadStoredSession() -> AuthSession?
    func saveSession(_ session: AuthSession) -> Bool
    func clearSession() -> Bool
}

struct DefaultAuthService: AuthService {
    private let tokenStore: SessionTokenStore
    private let logger: AppLogger
    private let analyticsService: AnalyticsService

    init(
        tokenStore: SessionTokenStore,
        logger: AppLogger,
        analyticsService: AnalyticsService
    ) {
        self.tokenStore = tokenStore
        self.logger = logger
        self.analyticsService = analyticsService
    }

    func loadStoredSession() -> AuthSession? {
        let session = tokenStore.loadSession()
        logger.debug(
            "Loaded stored auth session.",
            metadata: [
                "hasSession": session == nil ? "false" : "true",
                "token": SensitiveValueRedactor.redact(session?.accessToken ?? ""),
            ]
        )
        return session
    }

    func saveSession(_ session: AuthSession) -> Bool {
        let result = tokenStore.saveSession(session)
        logger.info(
            "Saved auth session.",
            metadata: [
                "success": result ? "true" : "false",
                "token": SensitiveValueRedactor.redact(session.accessToken),
            ]
        )

        if result {
            analyticsService.track(AnalyticsEvent(name: "auth_session_saved"))
        }

        return result
    }

    func clearSession() -> Bool {
        let result = tokenStore.clearSession()
        logger.info("Cleared auth session.", metadata: ["success": result ? "true" : "false"])

        if result {
            analyticsService.track(AnalyticsEvent(name: "auth_session_cleared"))
        }

        return result
    }
}
