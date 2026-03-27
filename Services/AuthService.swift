import Foundation

protocol AuthService {
    func loadStoredSession() -> AuthSession?
    func saveSession(_ session: AuthSession) -> Bool
    func clearSession() -> Bool
}

struct DefaultAuthService: AuthService {
    private let tokenStore: SessionTokenStore

    init(tokenStore: SessionTokenStore) {
        self.tokenStore = tokenStore
    }

    func loadStoredSession() -> AuthSession? {
        tokenStore.loadSession()
    }

    func saveSession(_ session: AuthSession) -> Bool {
        tokenStore.saveSession(session)
    }

    func clearSession() -> Bool {
        tokenStore.clearSession()
    }
}
