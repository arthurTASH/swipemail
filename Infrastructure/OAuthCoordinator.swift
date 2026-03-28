import AppAuth
import UIKit

@MainActor
final class OAuthCoordinator {
    var currentAuthorizationFlow: OIDExternalUserAgentSession?

    func presentingViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .topMostPresentedViewController()
    }

    func resumeExternalUserAgentFlow(with url: URL) -> Bool {
        guard let currentAuthorizationFlow,
              currentAuthorizationFlow.resumeExternalUserAgentFlow(with: url) else {
            return false
        }

        self.currentAuthorizationFlow = nil
        return true
    }
}

private extension UIViewController {
    func topMostPresentedViewController() -> UIViewController {
        var current = self
        while let presentedViewController = current.presentedViewController {
            current = presentedViewController
        }
        return current
    }
}
