import Foundation
import Security
import Logging
final class KeychainWrapper {
    static let standard = KeychainWrapper()
    private let lock = NSLock()
    
    struct KeychainItem {
        let key: String
        let data: Data
        let accessGroup: String?
        let accessibility: CFString
        let synchronizable: Bool
    }
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedStatus(OSStatus)
    }
    
    func set(_ data: Data, forKey key: String, withAccess accessibility: CFString = kSecAttrAccessibleAfterFirstUnlock) {
        lock.lock()
        defer { lock.unlock() }
        
        let query = createBaseQuery(forKey: key)
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            updateExistingItem(query: query, data: data, accessibility: accessibility)
        case errSecItemNotFound:
            addNewItem(query: query, data: data, accessibility: accessibility)
        default:
            handleKeychainError(status)
        }
    }
    
    func data(forKey key: String) throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        
        var query = createBaseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw KeychainError.itemNotFound
        }
        
        return data
    }
    
    func removeItem(forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let query = createBaseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func removeAllItems() throws {
        lock.lock()
        defer { lock.unlock() }
        
        let query = [kSecClass as String: kSecClassGenericPassword]
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    private func createBaseQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.ecosphere.exchange"
        ]
        
        #if !targetEnvironment(simulator)
        if let accessGroup = Bundle.main.infoDictionary?["KeychainAccessGroup"] as? String {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        #endif
        
        return query
    }
    
    private func addNewItem(query: [String: Any], data: Data, accessibility: CFString) {
        var newQuery = query
        newQuery[kSecValueData as String] = data
        newQuery[kSecAttrAccessible as String] = accessibility
        
        let status = SecItemAdd(newQuery as CFDictionary, nil)
        if status != errSecSuccess {
            handleKeychainError(status)
        }
    }
    
    private func updateExistingItem(query: [String: Any], data: Data, accessibility: CFString) {
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status != errSecSuccess {
            handleKeychainError(status)
        }
    }
    
    private func handleKeychainError(_ status: OSStatus) {
        SecurityLogger.shared.logSecurityEvent(SecurityEvent(
            id: UUID(),
            type: .systemAlert,
            severity: .high,
            timestamp: Date(),
            details: [
                "error": "Keychain operation failed",
                "status": String(status)
            ],
            metadata: createMetadata()
        ))
    }
    
    private func createMetadata() -> EventMetadata {
        return EventMetadata(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        )
    }
}
