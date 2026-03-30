import Foundation
import SwiftUI

@MainActor
final class AppSessionController: ObservableObject {
    enum Route {
        case launching
        case onboarding
        case inbox
        case settings
        case exited
    }

    @Published private(set) var route: Route = .launching
    @Published private(set) var inboxViewState: InboxViewState = .loading
    @Published var bannerState: StatusBannerState?
    @Published var onboardingEmailAddress = ""
    @Published private(set) var hasFailedSyncOperations = false
    @Published private(set) var isDrawerPresented = false
    @Published private(set) var connectivityStatus: ConnectivityStatus

    private let authService: AuthService
    private let gmailService: GmailService
    private let queueService: QueueService
    private let syncEngine: SyncEngine
    private let connectivityMonitor: ConnectivityMonitoring
    private let analyticsService: AnalyticsService
    private let logger: AppLogger

    init(
        authService: AuthService,
        gmailService: GmailService,
        queueService: QueueService,
        syncEngine: SyncEngine,
        connectivityMonitor: ConnectivityMonitoring,
        analyticsService: AnalyticsService,
        logger: AppLogger
    ) {
        self.authService = authService
        self.gmailService = gmailService
        self.queueService = queueService
        self.syncEngine = syncEngine
        self.connectivityMonitor = connectivityMonitor
        self.analyticsService = analyticsService
        self.logger = logger
        connectivityStatus = connectivityMonitor.currentStatus

        Task {
            await observeConnectivity()
        }
    }

    func bootstrap() async {
        do {
            if try await authService.restoreValidSession() == nil {
                route = .onboarding
                isDrawerPresented = false
                inboxViewState = .loading
                analyticsService.track(AnalyticsEvent(name: "app_bootstrap_routed_onboarding"))
                logger.info("App bootstrapped to onboarding.", metadata: [:])
            } else {
                route = .inbox
                isDrawerPresented = false
                analyticsService.track(AnalyticsEvent(name: "app_bootstrap_routed_inbox"))
                logger.info("App bootstrapped to inbox.", metadata: [:])
                await loadInbox()
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
                isDrawerPresented = false
                logger.info("Completed OAuth sign-in flow.", metadata: ["provider": session.provider.analyticsLabel])
                analyticsService.track(
                    AnalyticsEvent(
                        name: "oauth_sign_in_completed",
                        properties: ["provider": session.provider.analyticsLabel]
                    )
                )
                await loadInbox()
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
        analyticsService.track(AnalyticsEvent(name: "sign_out_requested"))

        Task {
            do {
                let revocationSucceeded = try await authService.disconnectCurrentSession()
                route = .onboarding
                isDrawerPresented = false
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

    func reloadInbox() {
        guard route == .inbox else {
            return
        }

        analyticsService.track(AnalyticsEvent(name: "inbox_reload_requested"))

        Task {
            await loadInbox()
        }
    }

    func apply(_ action: SwipeAction) {
        guard connectivityStatus.isOnline else {
            analyticsService.track(
                AnalyticsEvent(
                    name: "inbox_action_blocked_offline",
                    properties: ["action": action.analyticsLabel]
                )
            )
            logger.info(
                "Blocked inbox action while offline.",
                metadata: ["action": action.analyticsLabel]
            )
            presentBanner(message: offlineActionMessage, style: .error)
            return
        }

        guard case let .ready(messages) = inboxViewState, let currentMessage = messages.first else {
            return
        }

        let operation = action.makeOperation(for: currentMessage)
        let remainingMessages = Array(messages.dropFirst())

        if remainingMessages.isEmpty {
            inboxViewState = .empty(message: "No unread primary messages right now.")
        } else {
            inboxViewState = .ready(messages: remainingMessages)
        }

        Task {
            await queueService.enqueue(operation)
            let result = await syncEngine.syncPendingWork()
            await MainActor.run {
                handleSyncResult(result)
            }
        }

        analyticsService.track(
            AnalyticsEvent(
                name: "inbox_action_queued",
                properties: [
                    "action": action.analyticsLabel,
                    "messageID": currentMessage.id,
                ]
            )
        )
        logger.info(
            "Queued inbox action for background sync.",
            metadata: [
                "action": action.analyticsLabel,
                "messageID": currentMessage.id,
            ]
        )
        presentBanner(message: bannerMessage(for: action), style: .info)
    }

    func dismissBanner() {
        bannerState = nil
    }

    func toggleDrawer() {
        guard route == .inbox else {
            return
        }

        isDrawerPresented.toggle()
        analyticsService.track(
            AnalyticsEvent(name: isDrawerPresented ? "drawer_opened" : "drawer_closed")
        )
    }

    func closeDrawer() {
        isDrawerPresented = false
        analyticsService.track(AnalyticsEvent(name: "drawer_closed"))
    }

    func resumeSignedInFlow() {
        analyticsService.track(
            AnalyticsEvent(
                name: "signed_in_flow_resumed",
                properties: ["source": resumeSource]
            )
        )
        isDrawerPresented = false
        route = .inbox
    }

    func openSettings() {
        analyticsService.track(AnalyticsEvent(name: "settings_opened"))
        isDrawerPresented = false
        route = .settings
    }

    func closeSettings() {
        analyticsService.track(AnalyticsEvent(name: "settings_closed"))
        route = .inbox
    }

    func exitSignedInFlow() {
        analyticsService.track(
            AnalyticsEvent(
                name: "signed_in_flow_exited",
                properties: ["source": "drawer"]
            )
        )
        isDrawerPresented = false
        route = .exited
    }

    func disconnectFromSettings() {
        analyticsService.track(AnalyticsEvent(name: "settings_disconnect_requested"))

        Task {
            do {
                let revocationSucceeded = try await authService.disconnectCurrentSession()
                route = .onboarding
                isDrawerPresented = false
                inboxViewState = .loading
                analyticsService.track(AnalyticsEvent(name: "settings_disconnect_completed"))
                logger.info("Completed disconnect flow from Settings.", metadata: [:])

                if revocationSucceeded {
                    presentBanner(message: "Disconnected successfully.", style: .info)
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

    func exitFromSettings() {
        analyticsService.track(
            AnalyticsEvent(
                name: "signed_in_flow_exited",
                properties: ["source": "settings"]
            )
        )
        isDrawerPresented = false
        route = .exited
    }

    func retryFailedOperations() {
        analyticsService.track(AnalyticsEvent(name: "sync_retry_requested"))

        Task {
            await queueService.retryFailedOperations()
            let result = await syncEngine.syncPendingWork()
            await MainActor.run {
                handleSyncResult(result)
            }
        }
    }

    func handleOpenURL(_ url: URL) {
        guard authService.resumeExternalUserAgentFlow(with: url) else {
            logger.debug("Ignored incoming URL during auth handling.", metadata: ["url": url.absoluteString])
            return
        }

        logger.info("Resumed external OAuth user agent flow.", metadata: [:])
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        guard phase == .active else {
            return
        }

        Task {
            await handleForegroundResume()
        }
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

    private func observeConnectivity() async {
        for await status in connectivityMonitor.updates() {
            guard status != connectivityStatus else {
                continue
            }

            connectivityStatus = status
            analyticsService.track(
                AnalyticsEvent(
                    name: "connectivity_status_changed",
                    properties: ["status": status.isOnline ? "online" : "offline"]
                )
            )
            logger.info(
                "Connectivity status changed.",
                metadata: ["status": status.isOnline ? "online" : "offline"]
            )
        }
    }

    private func handleForegroundResume() async {
        guard route == .inbox || route == .exited || route == .settings else {
            return
        }

        let failedOperations = await queueService.failedOperations()
        guard !failedOperations.isEmpty else {
            return
        }

        hasFailedSyncOperations = true
        analyticsService.track(
            AnalyticsEvent(
                name: "foreground_resume_with_failed_operations",
                properties: ["failedOperationCount": String(failedOperations.count)]
            )
        )
        logger.info(
            "Foreground resume detected failed queue operations.",
            metadata: ["failedOperationCount": String(failedOperations.count)]
        )

        if connectivityStatus.isOnline {
            await queueService.retryFailedOperations()
            let result = await syncEngine.syncPendingWork()
            handleSyncResult(result)

            if result.failedOperations.isEmpty {
                presentBanner(message: "Pending inbox actions finished syncing.", style: .info)
            }
        } else {
            bannerState = StatusBannerState(
                message: offlineActionMessage,
                style: .error,
                actionTitle: "Retry",
                action: retryFailedOperations
            )
        }
    }

    private func clearInvalidSessionAfterRefreshFailure() {
        _ = authService.clearSession()
        route = .onboarding
        isDrawerPresented = false
        inboxViewState = .loading
        analyticsService.track(AnalyticsEvent(name: "auth_refresh_routed_onboarding"))
        logger.info("Routed to onboarding after refresh failure.", metadata: [:])
    }

    private func loadInbox() async {
        inboxViewState = .loading
        bannerState = nil
        hasFailedSyncOperations = false

        do {
            let messages = try await gmailService.fetchUnreadPrimaryMessages()

            if messages.isEmpty {
                inboxViewState = .empty(message: "No unread primary messages right now.")
                analyticsService.track(AnalyticsEvent(name: "inbox_loaded_empty"))
                logger.info("Loaded inbox with no unread primary messages.", metadata: [:])
            } else {
                inboxViewState = .ready(messages: messages)
                analyticsService.track(
                    AnalyticsEvent(
                        name: "inbox_loaded_ready",
                        properties: ["messageCount": String(messages.count)]
                    )
                )
                logger.info(
                    "Loaded unread primary inbox messages.",
                    metadata: ["messageCount": String(messages.count)]
                )
            }
        } catch let error as AppError {
            inboxViewState = .error(error)
            presentError(error)
        } catch {
            let error = AppError.network(message: error.localizedDescription)
            inboxViewState = .error(error)
            presentError(error)
        }
    }

    private func bannerMessage(for action: SwipeAction) -> String {
        switch action {
        case .markRead:
            return "Marked for read sync."
        case .followUp:
            return "Queued for follow up."
        case .delete:
            return "Queued for trash."
        case .spam:
            return "Queued for spam."
        }
    }

    private var offlineActionMessage: String {
        "You're offline. Reconnect to process inbox actions."
    }

    private var resumeSource: String {
        if isDrawerPresented {
            return "drawer"
        }

        switch route {
        case .exited:
            return "exited"
        case .settings:
            return "settings"
        default:
            return "inbox"
        }
    }

    private func handleSyncResult(_ result: SyncExecutionResult) {
        hasFailedSyncOperations = !result.failedOperations.isEmpty

        guard let failedOperation = result.failedOperations.first else {
            return
        }

        let failedMessage: String
        if case let .failed(error) = failedOperation.status {
            failedMessage = error.message
        } else {
            failedMessage = "A queued Gmail action failed."
        }

        bannerState = StatusBannerState(
            message: failedMessage,
            style: .error,
            actionTitle: "Retry",
            action: retryFailedOperations
        )
    }
}
