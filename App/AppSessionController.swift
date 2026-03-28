import Foundation

@MainActor
final class AppSessionController: ObservableObject {
    enum Route {
        case launching
        case onboarding
        case inbox
    }

    @Published private(set) var route: Route = .launching
    @Published private(set) var inboxViewState: InboxViewState = .loading
    @Published var bannerState: StatusBannerState?
    @Published var onboardingEmailAddress = ""

    private let authService: AuthService
    private let analyticsService: AnalyticsService
    private let logger: AppLogger

    init(
        authService: AuthService,
        analyticsService: AnalyticsService,
        logger: AppLogger
    ) {
        self.authService = authService
        self.analyticsService = analyticsService
        self.logger = logger
    }

    func bootstrap() async {
        do {
            if try await authService.restoreValidSession() == nil {
                route = .onboarding
                inboxViewState = .loading
                analyticsService.track(AnalyticsEvent(name: "app_bootstrap_routed_onboarding"))
                logger.info("App bootstrapped to onboarding.", metadata: [:])
            } else {
                route = .inbox
                inboxViewState = .empty(message: "Unread primary emails will appear here once Gmail is connected.")
                analyticsService.track(AnalyticsEvent(name: "app_bootstrap_routed_inbox"))
                logger.info("App bootstrapped to inbox.", metadata: [:])
            }
        } catch let error as AuthFlowError {
            clearInvalidSessionAfterRefreshFailure()
            presentError(AppError(authFlowError: error))
        } catch let error as AppError {
            clearInvalidSessionAfterRefreshFailure()
            presentError(error)
        } catch {
            clearInvalidSessionAfterRefreshFailure()
            presentError(.auth(message: error.localizedDescription))
        }
    }

    func beginSignIn() {
        let emailAddress = onboardingEmailAddress
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !emailAddress.isEmpty else {
            presentError(.auth(message: "Enter an email address to continue."))
            return
        }

        let provider = authService.provider(for: emailAddress)
        analyticsService.track(
            AnalyticsEvent(
                name: "auth_provider_resolved",
                properties: ["provider": provider.analyticsLabel]
            )
        )

        Task {
            do {
                let session = try await authService.signIn(with: emailAddress)
                guard authService.saveSession(session) else {
                    presentError(AppError(authFlowError: .persistenceFailed))
                    return
                }

                route = .inbox
                inboxViewState = .empty(message: "Placeholder inbox is empty. Gmail-backed messages will replace this state in Week 2.")
                logger.info("Completed OAuth sign-in flow.", metadata: ["provider": session.provider.analyticsLabel])
                analyticsService.track(
                    AnalyticsEvent(
                        name: "oauth_sign_in_completed",
                        properties: ["provider": session.provider.analyticsLabel]
                    )
                )
                presentBanner(message: "Signed in successfully.", style: .info)
            } catch let error as AuthFlowError {
                presentError(AppError(authFlowError: error))
            } catch let error as AppError {
                presentError(error)
            } catch {
                presentError(.auth(message: error.localizedDescription))
            }
        }
    }

    func signOut() {
        Task {
            do {
                let revocationSucceeded = try await authService.disconnectCurrentSession()
                route = .onboarding
                inboxViewState = .loading
                analyticsService.track(AnalyticsEvent(name: "placeholder_sign_out_completed"))
                logger.info("Completed auth sign-out flow.", metadata: [:])

                if revocationSucceeded {
                    presentBanner(message: "Signed out successfully.", style: .info)
                } else {
                    presentBanner(message: AuthFlowError.revocationFailed.message, style: .info)
                }
            } catch let error as AuthFlowError {
                presentError(AppError(authFlowError: error))
            } catch {
                presentError(.auth(message: error.localizedDescription))
            }
        }
    }

    func dismissBanner() {
        bannerState = nil
    }

    func handleOpenURL(_ url: URL) {
        guard authService.resumeExternalUserAgentFlow(with: url) else {
            logger.debug("Ignored incoming URL during auth handling.", metadata: ["url": url.absoluteString])
            return
        }

        logger.info("Resumed external OAuth user agent flow.", metadata: [:])
    }

    private func presentError(_ error: AppError) {
        logger.error("Presented app error.", metadata: ["message": error.message])
        bannerState = StatusBannerState(message: error.message, style: .error)
        if route == .inbox {
            inboxViewState = .error(error)
        }
    }

    private func presentBanner(message: String, style: StatusBannerState.Style) {
        bannerState = StatusBannerState(message: message, style: style)
    }

    private func clearInvalidSessionAfterRefreshFailure() {
        _ = authService.clearSession()
        route = .onboarding
        inboxViewState = .loading
        analyticsService.track(AnalyticsEvent(name: "auth_refresh_routed_onboarding"))
        logger.info("Routed to onboarding after refresh failure.", metadata: [:])
    }
}
