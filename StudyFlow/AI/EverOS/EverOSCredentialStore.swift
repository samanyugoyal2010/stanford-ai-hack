import Foundation
import Security

/// Loads the EverOS Cloud API key for StudyFlow.
///
/// Resolution order:
/// 1. Process environment `EVEROS_API_KEY` (Xcode scheme Environment Variables)
/// 2. macOS Keychain item `com.studyflow.app.everos` / account `api_key`
/// 3. Built-in development default (so the app runs without manual setup)
final class EverOSCredentialStore: Sendable {
    static let environmentKey = "EVEROS_API_KEY"
    private static let keychainService = "com.studyflow.app.everos"
    private static let keychainAccount = "api_key"

    /// Development / hackathon default so StudyFlow can talk to EverOS out of the box.
    private static let developmentAPIKey = "8fe61e32-2ede-4ec6-9858-c888d2178e06"

    /// Returns the API key if configured.
    func apiKey() -> String? {
        if let env = ProcessInfo.processInfo.environment[Self.environmentKey],
           !env.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return env.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let keychain = readKeychain(), !keychain.isEmpty {
            return keychain
        }
        return Self.developmentAPIKey
    }

    /// Persists a key to Keychain for local development (optional).
    func saveToKeychain(_ key: String) throws {
        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount
        ]
        SecItemDelete(query as CFDictionary)

        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    private func readKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
