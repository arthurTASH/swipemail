import Foundation

@MainActor
final class AppSessionController: ObservableObject {
    enum Route {
        case launching
        case onboarding
        case inbox
    }

    @Published private(set) var route: Route = .launching

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func bootstrap() {
        route = authService.loadStoredSession() == nil ? .onboarding : .inbox
    }

    func completePlaceholderSignIn() {
        let session = AuthSession(accessToken: "placeholder-token")
        guard authService.saveSession(session) else {
            return
        }

        route = .inbox
    }

    func signOut() {
        guard authService.clearSession() else {
            return
        }

        route = .onboarding
    }
}
