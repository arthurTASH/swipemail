import AppAuth
import Foundation

@MainActor
protocol AuthService: AnyObject {
    func loadStoredSession() -> AuthSession?
    func saveSession(_ session: AuthSession) -> Bool
    func clearSession() -> Bool
    func provider(for emailAddress: String) -> AuthProvider
    func signIn(with emailAddress: String) async throws -> AuthSession
    func resumeExternalUserAgentFlow(with url: URL) -> Bool
}

@MainActor
final class DefaultAuthService: AuthService {
    private let tokenStore: SessionTokenStore
    private let logger: AppLogger
    private let analyticsService: AnalyticsService
    private let providerRouter: AuthProviderRouting
    private let environment: AppEnvironment
    private let coordinator: OAuthCoordinator

    init(
        tokenStore: SessionTokenStore,
        logger: AppLogger,
        analyticsService: AnalyticsService,
        providerRouter: AuthProviderRouting,
        environment: AppEnvironment,
        coordinator: OAuthCoordinator
    ) {
        self.tokenStore = tokenStore
        self.logger = logger
        self.analyticsService = analyticsService
        self.providerRouter = providerRouter
        self.environment = environment
        self.coordinator = coordinator
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

    func provider(for emailAddress: String) -> AuthProvider {
        let provider = providerRouter.provider(for: emailAddress)
        logger.debug(
            "Resolved auth provider.",
            metadata: [
                "provider": provider.analyticsLabel,
                "email": SensitiveValueRedactor.redact(emailAddress),
            ]
        )
        return provider
    }

    func signIn(with emailAddress: String) async throws -> AuthSession {
        let provider = provider(for: emailAddress)
        guard case .google = provider else {
            throw AppError.auth(message: "Federated sign-in is not implemented yet.")
        }

        let presentingViewController = coordinator.presentingViewController()
        guard let presentingViewController else {
            throw AppError.auth(message: "Could not start sign-in because no presenting view controller was available.")
        }

        let configuration = OIDServiceConfiguration(
            authorizationEndpoint: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!,
            tokenEndpoint: URL(string: "https://oauth2.googleapis.com/token")!
        )

        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: environment.oauthClientID,
            clientSecret: nil,
            scopes: environment.gmailAPI.scopes,
            redirectURL: URL(string: environment.oauthRedirectURI)!,
            responseType: OIDResponseTypeCode,
            additionalParameters: [
                "access_type": "offline",
                "prompt": "consent",
                "login_hint": emailAddress,
            ]
        )

        logger.info("Starting Google OAuth flow.", metadata: ["email": SensitiveValueRedactor.redact(emailAddress)])
        analyticsService.track(AnalyticsEvent(name: "auth_flow_started", properties: ["provider": provider.analyticsLabel]))

        return try await withCheckedThrowingContinuation { continuation in
            coordinator.currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: request,
                presenting: presentingViewController
            ) { [weak self] authState, error in
                guard let self else {
                    continuation.resume(throwing: AppError.auth(message: "Auth flow was deallocated before completion."))
                    return
                }

                self.coordinator.currentAuthorizationFlow = nil

                if let error {
                    self.logger.error("OAuth authorization failed.", metadata: ["message": error.localizedDescription])
                    continuation.resume(throwing: AppError.auth(message: error.localizedDescription))
                    return
                }

                guard let tokenResponse = authState?.lastTokenResponse,
                      let accessToken = tokenResponse.accessToken else {
                    self.logger.error("OAuth authorization completed without an access token.", metadata: [:])
                    continuation.resume(throwing: AppError.auth(message: "OAuth flow did not return an access token."))
                    return
                }

                let session = AuthSession(
                    accessToken: accessToken,
                    refreshToken: tokenResponse.refreshToken,
                    idToken: tokenResponse.idToken,
                    accessTokenExpirationDate: tokenResponse.accessTokenExpirationDate,
                    provider: provider
                )

                self.logger.info(
                    "OAuth authorization completed.",
                    metadata: [
                        "provider": provider.analyticsLabel,
                        "token": SensitiveValueRedactor.redact(accessToken),
                    ]
                )
                self.analyticsService.track(
                    AnalyticsEvent(name: "auth_flow_completed", properties: ["provider": provider.analyticsLabel])
                )
                continuation.resume(returning: session)
            }
        }
    }

    func resumeExternalUserAgentFlow(with url: URL) -> Bool {
        coordinator.resumeExternalUserAgentFlow(with: url)
    }
}
