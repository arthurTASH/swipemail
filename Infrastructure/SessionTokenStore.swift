import Foundation
import Security

protocol SessionTokenStore {
    func loadSession() -> AuthSession?
    func saveSession(_ session: AuthSession) -> Bool
    func clearSession() -> Bool
}

struct KeychainSessionTokenStore: SessionTokenStore {
    private let service = "com.swipemail.auth"
    private let account = "default-session"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadSession() -> AuthSession? {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let session = try? decoder.decode(AuthSession.self, from: data) else {
            return nil
        }

        return session
    }

    func saveSession(_ session: AuthSession) -> Bool {
        guard let data = try? encoder.encode(session) else {
            return false
        }

        let deleteStatus = SecItemDelete(baseQuery() as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            return false
        }

        var query = baseQuery()
        query[kSecValueData as String] = data

        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    func clearSession() -> Bool {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
