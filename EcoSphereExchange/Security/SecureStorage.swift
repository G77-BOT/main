import Foundation
import Security
import LocalAuthentication
import MetricsKit

final class SecureStorage {
    private let queue = DispatchQueue(label: "com.ecosphere.security.storage", qos: .userInitiated)
    private let keychain = KeychainWrapper.standard
    
    struct StorageOptions {
        let accessibility: AccessibilityLevel
        let synchronizable: Bool
        let authentication: AuthenticationType
        
        static let defaultOptions = StorageOptions(
            accessibility: .afterFirstUnlock,
            synchronizable: false,
            authentication: .none
        )
    }
    
    enum AccessibilityLevel {
        case afterFirstUnlock
        case whenUnlocked
        case whenPasscodeSet
        
        var secAccessibility: CFString {
            switch self {
            case .afterFirstUnlock:
                return kSecAttrAccessibleAfterFirstUnlock
            case .whenUnlocked:
                return kSecAttrAccessibleWhenUnlocked
            case .whenPasscodeSet:
                return kSecAttrAccessibleWhenPasscodeSet
            }
        }
    }
    
    enum AuthenticationType {
        case none
        case biometric
        case password
    }
    
    func store(key: String, value: Any, options: StorageOptions = .defaultOptions) {
        queue.async {
            do {
                let encryptedData = try self.encrypt(value)
                let query = self.createSecureItemQuery(
                    for: key,
                    accessibility: options.accessibility,
                    synchronizable: options.synchronizable
                )
                
                self.saveToKeychain(query: query, data: encryptedData)
            } catch {
                self.handleStorageError(error, forKey: key)
            }
        }
    }
    
    func retrieve<T>(_ key: String) -> T? {
        queue.sync {
            do {
                guard let encryptedData = loadFromKeychain(key: key) else {
                    return nil
                }
                
                let decryptedData = try decrypt(encryptedData)
                return try JSONDecoder().decode(T.self, from: decryptedData)
            } catch {
                handleStorageError(error, forKey: key)
                return nil
            }
        }
    }
    
    func clear() {
        queue.async {
            let query = [
                kSecClass: kSecClassGenericPassword
            ] as [String: Any]
            
            SecItemDelete(query as CFDictionary)
        }
    }
    
    private func encrypt(_ value: Any) throws -> Data {
        let data = try JSONSerialization.data(withJSONObject: value)
        return try SecurityProvider.shared.encryptSensitiveData(data).ciphertext
    }
    
    private func decrypt(_ data: Data) throws -> Data {
        return try SecurityProvider.shared.decryptSensitiveData(data)
    }
    
    private func createSecureItemQuery(for key: String, accessibility: AccessibilityLevel, synchronizable: Bool) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: accessibility.secAccessibility,
            kSecAttrSynchronizable as String: synchronizable
        ]
        
        #if !targetEnvironment(simulator)
        query[kSecAttrAccessControl as String] = SecAccessControlCreateWithFlags(
            nil,
            accessibility.secAccessibility,
            .privateKeyUsage,
            nil
        )
        #endif
        
        return query
    }
    
    private func saveToKeychain(query: [String: Any], data: Data) {
        var status = SecItemCopyMatching(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            let updateQuery = [
                kSecValueData: data
            ] as [String: Any]
            
            status = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
        case errSecItemNotFound:
            var newQuery = query
            newQuery[kSecValueData as String] = data
            
            status = SecItemAdd(newQuery as CFDictionary, nil)
        default:
            break
        }
        
        if status != errSecSuccess {
            handleKeychainError(status)
        }
    }
    
    private func loadFromKeychain(key: String) -> Data? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ] as [String: Any]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return data
    }
}
