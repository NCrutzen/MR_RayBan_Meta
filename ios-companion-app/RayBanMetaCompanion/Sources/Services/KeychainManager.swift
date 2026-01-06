import Foundation
import Security

/// Secure credential storage using iOS Keychain
final class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.moyneroberts.mrsmartglasses"

    private init() {}

    // MARK: - Keychain Keys

    enum KeychainKey: String {
        case auth0ClientId = "auth0_client_id"
        case auth0ClientSecret = "auth0_client_secret"
        case auth0Audience = "auth0_audience"
        case auth0Domain = "auth0_domain"
        case accessToken = "access_token"
        case tokenExpiry = "token_expiry"
    }

    // MARK: - Save

    func save(_ value: String, for key: KeychainKey) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete existing item first
        delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Retrieve

    func retrieve(for key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    // MARK: - Delete

    @discardableResult
    func delete(_ key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Clear All

    func clearAll() {
        for key in [KeychainKey.auth0ClientId, .auth0ClientSecret, .auth0Audience, .auth0Domain, .accessToken, .tokenExpiry] {
            delete(key)
        }
    }

    // MARK: - Convenience Methods

    var hasAuth0Credentials: Bool {
        return retrieve(for: .auth0ClientId) != nil &&
               retrieve(for: .auth0ClientSecret) != nil
    }

    func saveAuth0Credentials(clientId: String, clientSecret: String, audience: String, domain: String) {
        _ = save(clientId, for: .auth0ClientId)
        _ = save(clientSecret, for: .auth0ClientSecret)
        _ = save(audience, for: .auth0Audience)
        _ = save(domain, for: .auth0Domain)
    }

    func saveAccessToken(_ token: String, expiresIn seconds: Int) {
        _ = save(token, for: .accessToken)
        let expiry = Date().addingTimeInterval(TimeInterval(seconds))
        _ = save(String(expiry.timeIntervalSince1970), for: .tokenExpiry)
    }

    var isTokenValid: Bool {
        guard let expiryString = retrieve(for: .tokenExpiry),
              let expiryTimestamp = Double(expiryString) else {
            return false
        }
        // Consider token expired 60 seconds before actual expiry
        return Date().timeIntervalSince1970 < (expiryTimestamp - 60)
    }

    var accessToken: String? {
        guard isTokenValid else { return nil }
        return retrieve(for: .accessToken)
    }
}
