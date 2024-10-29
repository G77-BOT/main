import Foundation
import Security

final class CertificatePinning {
    static let shared = CertificatePinning()
    
    private let securityProvider = SecurityProvider.shared
    private let logger = SecurityLogger.shared
    
    private var pinnedCertificates: [SecCertificate] = []
    private var pinnedPublicKeys: [SecKey] = []
    
    private init() {
        setupCertificatePinning()
    }
    
    // MARK: - Public Methods
    
    func validateCertificate(_ serverTrust: SecTrust, domain: String) -> Bool {
        // Set policy
        let policy = SecPolicyCreateSSL(true, domain as CFString)
        
        // Set trusted certificates
        SecTrustSetAnchorCertificates(serverTrust, pinnedCertificates as CFArray)
        SecTrustSetPolicies(serverTrust, policy)
        
        // Evaluate trust
        var error: CFError?
        let evaluationSucceeded = SecTrustEvaluateWithError(serverTrust, &error)
        
        if !evaluationSucceeded {
            logger.logError(error as Error? ?? SecurityError.certificateValidationFailed)
            return false
        }
        
        // Perform additional checks
        if !validateCertificateChain(serverTrust) {
            return false
        }
        
        if !validatePublicKey(serverTrust) {
            return false
        }
        
        return true
    }
    
    func addCertificate(_ certificate: SecCertificate) {
        pinnedCertificates.append(certificate)
        
        // Extract and store public key
        if let publicKey = extractPublicKey(from: certificate) {
            pinnedPublicKeys.append(publicKey)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupCertificatePinning() {
        // Load certificates from bundle
        loadBundledCertificates()
        
        // Load certificates from configuration
        loadConfiguredCertificates()
    }
    
    private func loadBundledCertificates() {
        guard let bundlePath = Bundle.main.path(forResource: "Certificates", ofType: "bundle"),
              let certificateBundle = Bundle(path: bundlePath) else {
            logger.logWarning("Certificate bundle not found")
            return
        }
        
        let certificateURLs = certificateBundle.urls(forResourcesWithExtension: "cer", subdirectory: nil) ?? []
        
        for url in certificateURLs {
            do {
                let certificateData = try Data(contentsOf: url)
                if let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) {
                    addCertificate(certificate)
                }
            } catch {
                logger.logError(error)
            }
        }
    }
    
    private func loadConfiguredCertificates() {
        NetworkConfig.pinnedCertificates.forEach { hash in
            if let certificate = retrieveCertificate(withHash: hash) {
                addCertificate(certificate)
            }
        }
    }
    
    private func validateCertificateChain(_ serverTrust: SecTrust) -> Bool {
        // Get certificate chain
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) else {
                continue
            }
            
            // Validate certificate
            if !validateIndividualCertificate(certificate) {
                logger.logWarning("Certificate validation failed for certificate at index \(i)")
                return false
            }
        }
        
        return true
    }
    
    private func validateIndividualCertificate(_ certificate: SecCertificate) -> Bool {
        // Get certificate data
        let certificateData = SecCertificateCopyData(certificate) as Data
        
        // Calculate hash
        let hash = calculateHash(for: certificateData)
        
        // Check if hash matches any pinned certificate
        return pinnedCertificates.contains { pinnedCertificate in
            let pinnedData = SecCertificateCopyData(pinnedCertificate) as Data
            return calculateHash(for: pinnedData) == hash
        }
    }
    
    private func validatePublicKey(_ serverTrust: SecTrust) -> Bool {
        guard let serverKey = SecTrustCopyPublicKey(serverTrust) else {
            return false
        }
        
        // Compare with pinned public keys
        return pinnedPublicKeys.contains { pinnedKey in
            comparePublicKeys(serverKey, pinnedKey)
        }
    }
    
    private func comparePublicKeys(_ key1: SecKey, _ key2: SecKey) -> Bool {
        guard let key1Data = extractPublicKeyData(key1),
              let key2Data = extractPublicKeyData(key2) else {
            return false
        }
        
        return key1Data == key2Data
    }
    
    private func extractPublicKey(from certificate: SecCertificate) -> SecKey? {
        // Create trust
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        SecTrustCreateWithCertificates(certificate, policy, &trust)
        
        guard let secTrust = trust else {
            return nil
        }
        
        // Evaluate trust
        var error: CFError?
        let evaluationSucceeded = SecTrustEvaluateWithError(secTrust, &error)
        
        guard evaluationSucceeded else {
            logger.logError(error as Error? ?? SecurityError.publicKeyExtractionFailed)
            return nil
        }
        
        return SecTrustCopyPublicKey(secTrust)
    }
    
    private func extractPublicKeyData(_ key: SecKey) -> Data? {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(key, &error) as Data? else {
            if let error = error?.takeRetainedValue() {
                logger.logError(error)
            }
            return nil
        }
        return data
    }
    
    private func calculateHash(for data: Data) -> String {
        let hash = data.withUnsafeBytes { bytes in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
            return Data(hash)
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    private func retrieveCertificate(withHash hash: String) -> SecCertificate? {
        // Implementation would depend on how certificates are stored
        // This is a placeholder for certificate retrieval logic
        return nil
    }
}

// MARK: - Supporting Types

enum SecurityError: LocalizedError {
    case certificateValidationFailed
    case publicKeyExtractionFailed
    case certificateNotFound
    
    var errorDescription: String? {
        switch self {
        case .certificateValidationFailed:
            return "Certificate validation failed"
        case .publicKeyExtractionFailed:
            return "Failed to extract public key"
        case .certificateNotFound:
            return "Certificate not found"
        }
    }
}
