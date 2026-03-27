import SwiftUI

@main
struct SwipeMailApp: App {
    @StateObject private var sessionController: AppSessionController

    init() {
        let dependencies = AppDependencies.live()
        _sessionController = StateObject(
            wrappedValue: AppSessionController(
                authService: dependencies.authService,
                analyticsService: dependencies.analyticsService,
                logger: dependencies.logger
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch sessionController.route {
                case .launching:
                    ProgressView("Loading SwipeMail")
                case .onboarding:
                    OnboardingView(connectAction: sessionController.completePlaceholderSignIn)
                case .inbox:
                    InboxPlaceholderView(
                        state: sessionController.inboxViewState,
                        signOutAction: sessionController.signOut
                    )
                }
            }
            .overlay(alignment: .top) {
                if let bannerState = sessionController.bannerState {
                    StatusBanner(state: bannerState, dismissAction: sessionController.dismissBanner)
                        .padding(.top, 12)
                }
            }
            .task {
                sessionController.bootstrap()
            }
        }
    }
}
