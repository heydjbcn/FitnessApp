//
//  Keychain.swift
//  ChamaFit
//
//  Secretos del usuario (API key del Coach, token de Spotify) en el llavero,
//  no en UserDefaults en claro. En pruebas se guardan en el dominio de
//  pruebas para no tocar el llavero real.
//

import Foundation
import Security

enum Keychain {
    private static let service = "Mauri.FitnessApp"

    static func string(for key: String) -> String? {
        if AppDefaults.isTesting { return AppDefaults.store.string(forKey: "keychain.\(key)") }
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: key,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func set(_ value: String?, for key: String) {
        if AppDefaults.isTesting { AppDefaults.store.set(value, forKey: "keychain.\(key)"); return }
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service,
                                   kSecAttrAccount as String: key]
        SecItemDelete(base as CFDictionary)
        guard let value, !value.isEmpty, let data = value.data(using: .utf8) else { return }
        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }
}
