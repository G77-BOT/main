import Foundation
import CryptoKit
import LocalAuthentication

final class SecurityProvider {
    static let shared = SecurityProvider()
    private let securityConfig = SecurityConfig.shared
    private let keychain = KeychainWrapper.standard
    
    // MARK: - Authentication
    private var loginAttempts: [String: Int] = [:]
    private var lastLoginTimestamp: [String: Date] = [:]
    
    func authenticateUser(userId: String, password: String) async throws -> Bool {
        guard !isUserLocked(userId) else {
            throw SecurityError.accountLocked
        }
        
        // Verify password hash with stored hash
        let isValid = try await verifyPassword(userId: userId, password: password)
        
        if isValid {
            resetLoginAttempts(for: userId)
            return true
        } else {
            try incrementLoginAttempts(for: userId)
            return false
        }
    }
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw SecurityError.biometricNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: "Authenticate to access your account") { success, error in
                if let error = error {
                    continuation.resume(throwing: SecurityError.biometricAuthenticationFailed(error))
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    // MARK: - Encryption
    func encryptData(_ data: Data) throws -> Data {
        let key = try getEncryptionKey()
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        return sealedBox.combined!
    }
    
    func decryptData(_ encryptedData: Data) throws -> Data {
        let key = try getEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Certificate Pinning
    func validateServerCertificate(_ serverTrust: SecTrust, domain: String) -> Bool {
        let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
        guard let serverCertificate = serverCertificate else { return false }
        
        let serverPublicKey = SecCertificateCopyKey(serverCertificate)
        guard let serverPublicKey = serverPublicKey else { return false }
        
        // Compare with pinned certificates
        let pinnedCertificates = SecurityConfig.CertificateConfig.production.pinnedPublicKeys
        let publicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil)
        guard let publicKeyData = publicKeyData as? Data else { return false }
        
        let publicKeyHash = SHA256.hash(data: publicKeyData)
        let publicKeyHashString = publicKeyHash.compactMap { String(format: "%02x", $0) }.joined()
        
        return pinnedCertificates.contains(publicKeyHashString)
    }
    
    // MARK: - Session Management
    private var activeSessions: [String: Date] = [:]
    
    func startSession(for userId: String) {
        activeSessions[userId] = Date()
    }
    
    func validateSession(for userId: String) -> Bool {
        guard let sessionStart = activeSessions[userId] else { return false }
        let sessionDuration = Date().timeIntervalSince(sessionStart)
        return sessionDuration < SecurityConfig.shared.SecuritySettings().sessionTimeout
    }
    
    func endSession(for userId: String) {
        activeSessions.removeValue(forKey: userId)
    }
    
    // MARK: - Private Helper Methods
    private func isUserLocked(_ userId: String) -> Bool {
        guard let attempts = loginAttempts[userId],
              let lastAttempt = lastLoginTimestamp[userId] else {
            return false
        }
        
        let lockoutDuration: TimeInterval = 300 // 5 minutes
        let timeSinceLastAttempt = Date().timeIntervalSince(lastAttempt)
        
        if timeSinceLastAttempt > lockoutDuration {
            resetLoginAttempts(for: userId)
            return false
        }
        
        return attempts >= SecurityConfig.shared.SecuritySettings().maxLoginAttempts
    }
    
    private func incrementLoginAttempts(for userId: String) throws {
        let currentAttempts = loginAttempts[userId] ?? 0
        loginAttempts[userId] = currentAttempts + 1
        lastLoginTimestamp[userId] = Date()
        
        if loginAttempts[userId]! >= SecurityConfig.shared.SecuritySettings().maxLoginAttempts {
            throw SecurityError.accountLocked
        }
    }
    
    private func resetLoginAttempts(for userId: String) {
        loginAttempts.removeValue(forKey: userId)
        lastLoginTimestamp.removeValue(forKey: userId)
    }
    
    private func verifyPassword(userId: String, password: String) async throws -> Bool {
        // Implement actual password verification logic here
        // This should include proper password hashing and comparison
        return SecurityConfig.SecurityThresholds.isPasswordValid(password)
    }
    
    private func getEncryptionKey() throws -> SymmetricKey {
        // In a real implementation, this would retrieve a stored key or generate one
        // For demonstration, we're creating a new key each time
        return SymmetricKey(size: .bits256)
    }
}
