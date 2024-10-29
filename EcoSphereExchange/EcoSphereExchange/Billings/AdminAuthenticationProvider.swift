import Foundation
import FirebaseFirestore
import LocalAuthentication

final class AdminAuthenticationProvider {
    private let securityProvider = SecurityProvider()
    private let biometricAuth = BiometricAuthenticator()
    private let rateLimiter = RateLimiter(maxAttempts: 3, timeWindow: 300)
    private let threatDetector = ThreatDetector(
        anomalyDetection: true,
        malwareScanning: true,
        jailbreakDetection: true
    )
    
    // MARK: - Models
    struct AdminSession {
        let id: UUID
        let accessLevel: AccessLevel
        let expirationDate: Date
        let encryptedToken: String
        let deviceFingerprint: String
        let lastRotationTime: Date
    }
    
    enum AccessLevel: String {
        case superAdmin
        case admin
        case restricted
    }
    
    // MARK: - Authentication
    func authenticateAdmin(credentials: AdminCredentials) async throws -> AdminSession {
        try preventBruteForce(adminId: credentials.id)
        try validateAccessLocation(credentials)
        
        guard try await biometricAuth.authenticate() else {
            rateLimiter.recordFailedAttempt(for: credentials.id)
            throw SecurityError.biometricAuthFailed
        }
        
        let hsm = try HSMProvider.shared.getSecureElement()
        let verifiedCredentials = try hsm.verifyCredentials(credentials)
        
        guard TOTPValidator.validate(credentials.totp) else {
            rateLimiter.recordFailedAttempt(for: credentials.id)
            throw SecurityError.invalidTOTP
        }
        
        // Threat detection
        guard await threatDetector.performSecurityCheck() else {
            throw SecurityError.securityCheckFailed
        }
        
        let session = createAdminSession(for: verifiedCredentials)
        await logAdminAction(.sessionCreated, session: session)
        startSessionMonitoring(session)
        
        return session
    }
    
    // MARK: - Session Management
    private func createAdminSession(for credentials: VerifiedAdminCredentials) -> AdminSession {
        let sessionToken = SecurityProvider.generateSecureToken()
        let encryptedToken = SecurityProvider.encrypt(sessionToken)
        KeychainManager.shared.storeAdminToken(sessionToken)
        
        return AdminSession(
            id: UUID(),
            accessLevel: credentials.accessLevel,
            expirationDate: Date().addingTimeInterval(900),
            encryptedToken: encryptedToken,
            deviceFingerprint: SecurityProvider.deviceFingerprint,
            lastRotationTime: Date()
        )
    }
    
    func rotateSession(_ session: AdminSession) async throws -> AdminSession {
        guard validateSession(session) else {
            throw SecurityError.invalidSession
        }
        
        let newSession = createAdminSession(for: session.credentials)
        try await invalidateSession(session)
        await logAdminAction(.sessionRotated, session: newSession)
        
        return newSession
    }
    
    // MARK: - Security Measures
    private func preventBruteForce(adminId: String) throws {
        guard !rateLimiter.isLimited(for: adminId) else {
            throw SecurityError.tooManyAttempts
        }
    }
    
    private func validateAccessLocation(_ credentials: AdminCredentials) throws {
        guard let ipAddress = NetworkManager.shared.currentIPAddress,
              SecurityProvider.isAllowedIP(ipAddress),
              LocationValidator.isWithinAllowedRegion() else {
            throw SecurityError.unauthorizedLocation
        }
    }
    
    private func validateSession(_ session: AdminSession) -> Bool {
        guard session.expirationDate > Date(),
              let storedToken = KeychainManager.shared.getAdminToken(),
              session.encryptedToken == storedToken,
              session.deviceFingerprint == SecurityProvider.deviceFingerprint else {
            return false
        }
        return true
    }
    
    // MARK: - Monitoring and Logging
    private func startSessionMonitoring(_ session: AdminSession) {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] timer in
            guard let self = self,
                  self.validateSession(session) else {
                timer.invalidate()
                self?.terminateSession(session)
                return
            }
        }
    }
    
    private func logAdminAction(_ action: AdminAction, session: AdminSession) async {
        await Firestore.firestore().collection("adminAudit").addDocument(data: [
            "adminId": session.id.uuidString,
            "action": action.rawValue,
            "timestamp": FieldValue.serverTimestamp(),
            "accessLevel": session.accessLevel.rawValue,
            "deviceInfo": SecurityProvider.deviceFingerprint,
            "ipAddress": NetworkManager.shared.currentIPAddress ?? "unknown"
        ])
    }
    
    func terminateSession(_ session: AdminSession) {
        KeychainManager.shared.removeAdminToken()
        Task {
            await logAdminAction(.sessionTerminated, session: session)
        }
        NotificationCenter.default.post(name: .adminSessionTerminated, object: nil)
    }
}
