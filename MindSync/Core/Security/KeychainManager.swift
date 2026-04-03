import Foundation
import Security

protocol KeychainManagerProtocol {
    func save(_ value: String, for key: String) throws
    func retrieve(for key: String) throws -> String
    func delete(for key: String) throws
}

final class KeychainManager: KeychainManagerProtocol {

    private let service: String

    init(service: String = AppConstants.Keychain.service) {
        self.service = service
    }

    func save(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw AppError.keychainFailed(operation: "encode")
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        let attributes: [CFString: Any] = [kSecValueData: data]

        let deleteStatus = SecItemDelete(query as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            logError("Keychain delete before save failed: \(deleteStatus)")
            throw AppError.keychainFailed(operation: "delete-before-save")
        }

        let addQuery = query.merging(attributes) { _, new in new }
        let status = SecItemAdd(addQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            logError("Keychain save failed: \(status) for key [REDACTED]")
            throw AppError.keychainFailed(operation: "save")
        }
    }

    func retrieve(for key: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            if status == errSecItemNotFound {
                throw AppError.missingAPIKey(provider: key)
            }
            logError("Keychain retrieve failed: \(status)")
            throw AppError.keychainFailed(operation: "retrieve")
        }

        guard let value = String(data: data, encoding: .utf8) else {
            throw AppError.keychainFailed(operation: "decode")
        }

        return value
    }

    func delete(for key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            logError("Keychain delete failed: \(status)")
            throw AppError.keychainFailed(operation: "delete")
        }
    }
}
