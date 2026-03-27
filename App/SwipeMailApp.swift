import SwiftUI

@main
struct SwipeMailApp: App {
    private let dependencies = AppDependencies.live()

    @StateObject private var sessionController: AppSessionController

    init() {
        let dependencies = AppDependencies.live()
        self.dependencies = dependencies
        _sessionController = StateObject(
            wrappedValue: AppSessionController(authService: dependencies.authService)
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
                    InboxPlaceholderView(signOutAction: sessionController.signOut)
                }
            }
            .task {
                sessionController.bootstrap()
            }
        }
    }
}
