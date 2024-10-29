import Foundation
import Security
import CryptoKit

final class EncryptionManager {
    static let shared = EncryptionManager()
    
    private let secureStorage = SecureStorage.shared
    private let queue = DispatchQueue(label: "encryption.queue", qos: .userInitiated)
    
    private enum Constants {
        static let keyIdentifier = "com.ecosphere.encryption.key"
        static let keychainAccessGroup = "com.ecosphere.keychain"
        static let ivSize = 12
    }
    
    private var encryptionKey: SymmetricKey?
    
    private init() {
        setupEncryptionKey()
    }
    
    // MARK: - Public Methods
    
    func encrypt(_ data: Data) async throws -> EncryptedData {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: EncryptionError.managerDeallocated)
                    return
                }
                
                do {
                    let key = try self.getOrCreateKey()
                    let encrypted = try self.performEncryption(data, using: key)
                    continuation.resume(returning: encrypted)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func decrypt(_ encryptedData: EncryptedData) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: EncryptionError.managerDeallocated)
                    return
                }
                
                do {
                    let key = try self.getOrCreateKey()
                    let decrypted = try self.performDecryption(encryptedData, using: key)
                    continuation.resume(returning: decrypted)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func rotateKey() async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: EncryptionError.managerDeallocated)
                    return
                }
                
                do {
                    let newKey = SymmetricKey(size: .bits256)
                    try self.storeKey(newKey)
                    self.encryptionKey = newKey
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupEncryptionKey() {
        queue.async { [weak self] in
            do {
                _ = try self?.getOrCreateKey()
            } catch {
                SecurityLogger.shared.logError(error)
            }
        }
    }
    
    private func getOrCreateKey() throws -> SymmetricKey {
        if let existingKey = encryptionKey {
            return existingKey
        }
        
        // Try to retrieve from keychain
        if let storedKey = try? retrieveKey() {
            encryptionKey = storedKey
            return storedKey
        }
        
        // Generate and store new key
        let newKey = SymmetricKey(size: .bits256)
        try storeKey(newKey)
        encryptionKey = newKey
        return newKey
    }
    
    private func performEncryption(_ data: Data, using key: SymmetricKey) throws -> EncryptedData {
        // Generate random IV
        var iv = Data(count: Constants.ivSize)
        let result = iv.withUnsafeMutableBytes { pointer in
            SecRandomCopyBytes(kSecRandomDefault, Constants.ivSize, pointer.baseAddress!)
        }
        guard result == errSecSuccess else {
            throw EncryptionError.ivGenerationFailed
        }
        
        let nonce = try AES.GCM.Nonce(data: iv)
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        
        return EncryptedData(
            ciphertext: sealedBox.ciphertext,
            nonce: sealedBox.nonce.withUnsafeBytes(Array.init),
            tag: sealedBox.tag
        )
    }
    
    private func performDecryption(_ encryptedData: EncryptedData, using key: SymmetricKey) throws -> Data {
        let nonce = try AES.GCM.Nonce(data: encryptedData.nonce)
        let sealedBox = try AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: encryptedData.ciphertext,
            tag: encryptedData.tag
        )
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    private func storeKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: Constants.keyIdentifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccessGroup as String: Constants.keychainAccessGroup
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            throw EncryptionError.keyStorageFailed(status: status)
        }
    }
    
    private func retrieveKey() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: Constants.keyIdentifier,
            kSecReturnData as String: true,
            kSecAttrAccessGroup as String: Constants.keychainAccessGroup
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            if status == errSecItemNotFound {
                return nil
            }
            throw EncryptionError.keyRetrievalFailed(status: status)
        }
        
        return SymmetricKey(data: keyData)
    }
}

// MARK: - Supporting Types

struct EncryptedData: Codable {
    let ciphertext: Data
    let nonce: Data
    let tag: Data
}

enum EncryptionError: LocalizedError {
    case managerDeallocated
    case keyStorageFailed(status: OSStatus)
    case keyRetrievalFailed(status: OSStatus)
    case ivGenerationFailed
    case encryptionFailed
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .managerDeallocated:
            return "Encryption manager was deallocated"
        case .keyStorageFailed(let status):
            return "Failed to store encryption key (status: \(status))"
        case .keyRetrievalFailed(let status):
            return "Failed to retrieve encryption key (status: \(status))"
        case .ivGenerationFailed:
            return "Failed to generate random IV"
        case .encryptionFailed:
            return "Encryption operation failed"
        case .decryptionFailed:
            return "Decryption operation failed"
        }
    }
}
