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
    func restoreValidSession() async throws -> AuthSession?
    func disconnectCurrentSession() async throws -> Bool
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
            if case let .federated(domain) = provider {
                throw AuthFlowError.unsupportedProvider(domain: domain)
            }
            throw AuthFlowError.unknown(message: "Unsupported auth provider.")
        }

        let presentingViewController = coordinator.presentingViewController()
        guard let presentingViewController else {
            throw AuthFlowError.presentationUnavailable
        }

        guard let configuration = googleOAuthConfiguration(),
              let redirectURL = URL(string: environment.oauthRedirectURI) else {
            throw AuthFlowError.configurationInvalid
        }

        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: environment.oauthClientID,
            clientSecret: nil,
            scopes: environment.gmailAPI.scopes,
            redirectURL: redirectURL,
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
                    continuation.resume(throwing: AuthFlowError.unknown(message: "Auth flow was deallocated before completion."))
                    return
                }

                self.coordinator.currentAuthorizationFlow = nil

                if let error {
                    self.logger.error("OAuth authorization failed.", metadata: ["message": error.localizedDescription])
                    continuation.resume(throwing: self.mapAuthError(error))
                    return
                }

                guard let tokenResponse = authState?.lastTokenResponse,
                      let accessToken = tokenResponse.accessToken else {
                    self.logger.error("OAuth authorization completed without an access token.", metadata: [:])
                    continuation.resume(throwing: AuthFlowError.unknown(message: "OAuth flow did not return an access token."))
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

    func restoreValidSession() async throws -> AuthSession? {
        guard let storedSession = loadStoredSession() else {
            return nil
        }

        guard requiresRefresh(for: storedSession) else {
            logger.info("Stored auth session is still valid.", metadata: ["provider": storedSession.provider.analyticsLabel])
            return storedSession
        }

        guard let refreshToken = storedSession.refreshToken,
              let configuration = googleOAuthConfiguration(),
              let redirectURL = URL(string: environment.oauthRedirectURI) else {
            logger.error("Stored session requires refresh but has no refresh token.", metadata: [:])
            throw AuthFlowError.refreshFailed(message: "Stored session expired and cannot be refreshed.")
        }

        let tokenRequest = OIDTokenRequest(
            configuration: configuration,
            grantType: OIDGrantTypeRefreshToken,
            authorizationCode: nil,
            redirectURL: redirectURL,
            clientID: environment.oauthClientID,
            clientSecret: nil,
            scope: environment.gmailAPI.scopes.joined(separator: " "),
            refreshToken: refreshToken,
            codeVerifier: nil,
            additionalParameters: nil
        )

        logger.info("Refreshing stored auth session.", metadata: ["provider": storedSession.provider.analyticsLabel])
        analyticsService.track(
            AnalyticsEvent(name: "auth_refresh_started", properties: ["provider": storedSession.provider.analyticsLabel])
        )

        return try await withCheckedThrowingContinuation { continuation in
            OIDAuthorizationService.perform(tokenRequest) { [weak self] tokenResponse, error in
                guard let self else {
                    continuation.resume(throwing: AuthFlowError.unknown(message: "Refresh flow was deallocated before completion."))
                    return
                }

                if let error {
                    self.logger.error("Auth refresh failed.", metadata: ["message": error.localizedDescription])
                    self.analyticsService.track(
                        AnalyticsEvent(
                            name: "auth_refresh_failed",
                            properties: ["provider": storedSession.provider.analyticsLabel]
                        )
                    )
                    continuation.resume(throwing: AuthFlowError.refreshFailed(message: error.localizedDescription))
                    return
                }

                guard let tokenResponse, let accessToken = tokenResponse.accessToken else {
                    self.logger.error("Auth refresh completed without an access token.", metadata: [:])
                    continuation.resume(throwing: AuthFlowError.refreshFailed(message: "Refresh did not return a valid access token."))
                    return
                }

                let refreshedSession = AuthSession(
                    accessToken: accessToken,
                    refreshToken: tokenResponse.refreshToken ?? storedSession.refreshToken,
                    idToken: tokenResponse.idToken ?? storedSession.idToken,
                    accessTokenExpirationDate: tokenResponse.accessTokenExpirationDate,
                    provider: storedSession.provider
                )

                guard self.saveSession(refreshedSession) else {
                    self.logger.error("Refreshed session could not be persisted.", metadata: [:])
                    continuation.resume(throwing: AuthFlowError.persistenceFailed)
                    return
                }

                self.logger.info(
                    "Auth refresh completed.",
                    metadata: [
                        "provider": storedSession.provider.analyticsLabel,
                        "token": SensitiveValueRedactor.redact(accessToken),
                    ]
                )
                self.analyticsService.track(
                    AnalyticsEvent(
                        name: "auth_refresh_completed",
                        properties: ["provider": storedSession.provider.analyticsLabel]
                    )
                )
                continuation.resume(returning: refreshedSession)
            }
        }
    }

    func disconnectCurrentSession() async throws -> Bool {
        let storedSession = loadStoredSession()
        let revocationSucceeded = try await revokeIfSupported(for: storedSession)

        guard clearSession() else {
            throw AuthFlowError.persistenceFailed
        }

        return revocationSucceeded
    }

    private func requiresRefresh(for session: AuthSession) -> Bool {
        guard let expirationDate = session.accessTokenExpirationDate else {
            return false
        }

        // Refresh slightly before expiry to avoid launching with a token that is about to fail.
        let refreshLeadTime: TimeInterval = 60
        return expirationDate.timeIntervalSinceNow <= refreshLeadTime
    }

    private func googleOAuthConfiguration() -> OIDServiceConfiguration? {
        guard let authorizationEndpoint = URL(string: "https://accounts.google.com/o/oauth2/v2/auth"),
              let tokenEndpoint = URL(string: "https://oauth2.googleapis.com/token") else {
            return nil
        }

        return OIDServiceConfiguration(
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint
        )
    }

    private func revokeIfSupported(for session: AuthSession?) async throws -> Bool {
        guard let session else {
            return true
        }

        guard case .google = session.provider else {
            return true
        }

        let tokenToRevoke = session.refreshToken ?? session.accessToken
        guard !tokenToRevoke.isEmpty else {
            return true
        }

        guard let revokeURL = URL(string: "https://oauth2.googleapis.com/revoke") else {
            throw AuthFlowError.configurationInvalid
        }

        var request = URLRequest(url: revokeURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "token", value: tokenToRevoke)]
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        logger.info("Revoking Google auth token.", metadata: ["token": SensitiveValueRedactor.redact(tokenToRevoke)])

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.revocationFailed
        }

        if 200..<300 ~= httpResponse.statusCode {
            analyticsService.track(
                AnalyticsEvent(name: "auth_revocation_completed", properties: ["provider": session.provider.analyticsLabel])
            )
            return true
        }

        analyticsService.track(
            AnalyticsEvent(name: "auth_revocation_failed", properties: ["provider": session.provider.analyticsLabel])
        )
        logger.error("Google auth revocation failed.", metadata: ["statusCode": String(httpResponse.statusCode)])
        return false
    }

    private func mapAuthError(_ error: Error) -> AuthFlowError {
        let nsError = error as NSError
        if nsError.domain == OIDGeneralErrorDomain {
            switch nsError.code {
            case -3, -4:
                return .cancelled
            case -5:
                return .refreshFailed(message: nsError.localizedDescription)
            default:
                return .unknown(message: nsError.localizedDescription)
            }
        }

        return .unknown(message: nsError.localizedDescription)
    }
}
