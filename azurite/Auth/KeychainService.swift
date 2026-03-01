//
//  KeychainService.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import Foundation
import Security

/// A lightweight wrapper around the macOS Keychain for storing AT Protocol credentials.
enum KeychainService {

    private static let service = "uk.ewancroft.azurite"
    private static let handleKey = "handle"
    private static let passwordKey = "appPassword"

    // MARK: - Save

    static func saveCredentials(handle: String, appPassword: String) {
        save(key: handleKey, value: handle)
        save(key: passwordKey, value: appPassword)
    }

    // MARK: - Load

    static func loadCredentials() -> (handle: String, appPassword: String)? {
        guard let handle = load(key: handleKey),
              let appPassword = load(key: passwordKey) else {
            return nil
        }
        return (handle, appPassword)
    }

    // MARK: - Delete

    static func deleteCredentials() {
        delete(key: handleKey)
        delete(key: passwordKey)
    }

    // MARK: - Private helpers

    private static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Try to update an existing item first.
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let attributes: [CFString: Any] = [kSecValueData: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            // Item doesn't exist yet — add it.
            var newItem = query
            newItem[kSecValueData] = data
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }

    private static func load(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    private static func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
