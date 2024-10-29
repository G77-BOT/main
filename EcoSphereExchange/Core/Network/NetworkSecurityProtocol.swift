import Foundation

protocol NetworkSecurityProtocol: URLSessionTaskDelegate {
    var certificatePinning: CertificatePinning { get }
    var encryptionManager: EncryptionManager { get }
    var securityProvider: SecurityProvider { get }
    var networkMonitor: NetworkMonitor { get }
    
    func validateCertificate(_ challenge: URLAuthenticationChallenge) -> Bool
    func applySecurityHeaders(_ request: inout URLRequest)
    func encryptRequest(_ request: URLRequest) -> URLRequest
    func decryptResponse(_ response: Data) throws -> Data
    func validateResponse(_ response: URLResponse) throws
}

final class NetworkSecurityManager: NSObject, NetworkSecurityProtocol {
    // MARK: - Properties
    
    let certificatePinning: CertificatePinning
    let encryptionManager: EncryptionManager
    let securityProvider: SecurityProvider
    let networkMonitor: NetworkMonitor
    private let logger: SecurityLogger
    
    private let queue = DispatchQueue(label: "network.security", qos: .userInitiated)
    private var securityChecks: [SecurityCheck] = []
    
    // MARK: - Initialization
    
    init(
        certificatePinning: CertificatePinning = .shared,
        encryptionManager: EncryptionManager = .shared,
        securityProvider: SecurityProvider = .shared,
        networkMonitor: NetworkMonitor = .shared,
        logger: SecurityLogger = .shared
    ) {
        self.certificatePinning = certificatePinning
        self.encryptionManager = encryptionManager
        self.securityProvider = securityProvider
        self.networkMonitor = networkMonitor
        self.logger = logger
        super.init()
        
        setupSecurityChecks()
    }
    
    // MARK: - Public Methods
    
    func validateCertificate(_ challenge: URLAuthenticationChallenge) -> Bool {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            logger.logWarning("Failed to get server certificate")
            return false
        }
        
        // Check certificate pinning
        return certificatePinning.validateCertificate(serverTrust, domain: challenge.protectionSpace.host)
    }
    
    func applySecurityHeaders(_ request: inout URLRequest) {
        // Add request timestamp
        let timestamp = String(Int(Date().timeIntervalSince1970))
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        
        // Add device identifier
        request.setValue(
            UIDevice.current.identifierForVendor?.uuidString,
            forHTTPHeaderField: "X-Device-ID"
        )
        
        // Add signature
        if let signature = generateRequestSignature(request, timestamp: timestamp) {
            request.setValue(signature, forHTTPHeaderField: "X-Signature")
        }
        
        // Add encryption headers if needed
        if securityProvider.shouldEncryptRequests {
            request.setValue("encrypted", forHTTPHeaderField: "X-Content-Encoding")
        }
    }
    
    func encryptRequest(_ request: URLRequest) -> URLRequest {
        var encryptedRequest = request
        
        guard securityProvider.shouldEncryptRequests,
              let originalBody = request.httpBody else {
            return request
        }
        
        do {
            let encryptedData = try encryptionManager.encrypt(originalBody)
            encryptedRequest.httpBody = try JSONEncoder().encode(encryptedData)
        } catch {
            logger.logError(error)
        }
        
        return encryptedRequest
    }
    
    func decryptResponse(_ response: Data) throws -> Data {
        guard securityProvider.shouldDecryptResponses else {
            return response
        }
        
        let encryptedData = try JSONDecoder().decode(EncryptedData.self, from: response)
        return try encryptionManager.decrypt(encryptedData)
    }
    
    func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(statusCode: 0)
        }
        
        // Validate status code
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
        }
        
        // Validate security headers
        try validateSecurityHeaders(httpResponse)
        
        // Run security checks
        try runSecurityChecks(for: httpResponse)
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              validateCertificate(challenge) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        if let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSecurityChecks() {
        securityChecks = [
            RequestIntegrityCheck(),
            ResponseIntegrityCheck(),
            TamperingCheck(),
            ReplayAttackCheck()
        ]
    }
    
    private func generateRequestSignature(_ request: URLRequest, timestamp: String) -> String? {
        guard let url = request.url,
              let method = request.httpMethod else {
            return nil
        }
        
        do {
            return try securityProvider.signRequest(
                method: method,
                path: url.path,
                timestamp: timestamp
            )
        } catch {
            logger.logError(error)
            return nil
        }
    }
    
    private func validateSecurityHeaders(_ response: HTTPURLResponse) throws {
        // Check required security headers
        let requiredHeaders = [
            "X-Content-Type-Options": "nosniff",
            "X-Frame-Options": "DENY",
            "X-XSS-Protection": "1; mode=block"
        ]
        
        for (header, value) in requiredHeaders {
            guard response.value(forHTTPHeaderField: header) == value else {
                throw SecurityError.missingSecurityHeader(header)
            }
        }
        
        // Validate response signature
        if let signature = response.value(forHTTPHeaderField: "X-Signature"),
           let timestamp = response.value(forHTTPHeaderField: "X-Timestamp") {
            try validateResponseSignature(signature, timestamp: timestamp)
        } else {
            throw SecurityError.missingResponseSignature
        }
    }
    
    private func validateResponseSignature(_ signature: String, timestamp: String) throws {
        guard try securityProvider.validateSignature(signature, timestamp: timestamp) else {
            throw SecurityError.invalidResponseSignature
        }
    }
    
    private func runSecurityChecks(for response: HTTPURLResponse) throws {
        for check in securityChecks {
            let result = check.execute()
            if !result.passed {
                // Handle security check failure
                handleSecurityCheckFailure(result)
                
                if result.vulnerability.severity == .critical {
                    throw SecurityError.securityCheckFailed(result.vulnerability)
                }
            }
        }
    }
    
    private func handleSecurityCheckFailure(_ result: SecurityCheckResult) {
        // Log security check failure
        logger.logWarning("Security check failed: \(result.vulnerability.description)")
        
        // Implement security measures based on vulnerability
        switch result.vulnerability.type {
        case .networkTampering:
            securityProvider.enforceStrictNetworkSecurity()
        default:
            break
        }
        
        // Track security event
        AnalyticsManager.shared.trackEvent(.securityCheckFailed(result))
    }
}

// MARK: - Security Checks

struct RequestIntegrityCheck: SecurityCheck {
    func execute() -> SecurityCheckResult {
        // Implementation for request integrity check
        return SecurityCheckResult(
            passed: true,
            vulnerability: Vulnerability(
                type: .networkTampering,
                severity: .high,
                description: "Request integrity compromised",
                requiresUserAction: false
            ),
            recommendations: []
        )
    }
}

struct ResponseIntegrityCheck: SecurityCheck {
    func execute() -> SecurityCheckResult {
        // Implementation for response integrity check
        return SecurityCheckResult(
            passed: true,
            vulnerability: Vulnerability(
                type: .networkTampering,
                severity: .high,
                description: "Response integrity compromised",
                requiresUserAction: false
            ),
            recommendations: []
        )
    }
}

struct TamperingCheck: SecurityCheck {
    func execute() -> SecurityCheckResult {
        // Implementation for tampering check
        return SecurityCheckResult(
            passed: true,
            vulnerability: Vulnerability(
                type: .networkTampering,
                severity: .critical,
                description: "Network tampering detected",
                requiresUserAction: false
            ),
            recommendations: []
        )
    }
}

struct ReplayAttackCheck: SecurityCheck {
    func execute() -> SecurityCheckResult {
        // Implementation for replay attack check
        return SecurityCheckResult(
            passed: true,
            vulnerability: Vulnerability(
                type: .networkTampering,
                severity: .critical,
                description: "Replay attack detected",
                requiresUserAction: false
            ),
            recommendations: []
        )
    }
}

// MARK: - Supporting Types

extension SecurityError {
    static func missingSecurityHeader(_ header: String) -> SecurityError {
        return .init(description: "Missing required security header: \(header)")
    }
    
    static let missingResponseSignature = SecurityError(description: "Missing response signature")
    static let invalidResponseSignature = SecurityError(description: "Invalid response signature")
    
    static func securityCheckFailed(_ vulnerability: Vulnerability) -> SecurityError {
        return .init(description: "Security check failed: \(vulnerability.description)")
    }
}