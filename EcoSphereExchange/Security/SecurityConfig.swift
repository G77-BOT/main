import Foundation

final class SecurityConfig {
    static let shared = SecurityConfig()
    
    // Endpoint Configuration
    static let notificationEndpoint = URL(string: "https://api.ecosphere.exchange/security/notifications")!
    static let securityApiEndpoint = URL(string: "https://api.ecosphere.exchange/security")!
    
    struct SecuritySettings {
        // Authentication Settings
        let maxLoginAttempts: Int = 3
        let sessionTimeout: TimeInterval = 900 // 15 minutes
        let requireBiometrics: Bool = true
        
        // Encryption Settings
        let minimumKeyLength: Int = 256
        let preferredEncryptionAlgorithm: String = "AES-GCM"
        let keyRotationInterval: TimeInterval = 86400 // 24 hours
        
        // Network Security
        let requiredTLSVersion: String = "1.3"
        let allowedCipherSuites: [String] = ["TLS_AES_256_GCM_SHA384"]
        let certificatePinningEnabled: Bool = true
        
        // Monitoring Settings
        let anomalyDetectionThreshold: Double = 0.85
        let monitoringInterval: TimeInterval = 300 // 5 minutes
        let logRetentionDays: Int = 30
    }
    
    // Security Thresholds
    struct SecurityThresholds {
        static let maxConcurrentSessions = 1
        static let maxPayloadSize = 10_485_760 // 10MB
        static let minPasswordLength = 12
        static let maxPasswordAge = 90 // days
        
        static func isPasswordValid(_ password: String) -> Bool {
            let passwordRules = [
                "length": password.count >= minPasswordLength,
                "uppercase": password.contains(where: { $0.isUppercase }),
                "lowercase": password.contains(where: { $0.isLowercase }),
                "numbers": password.contains(where: { $0.isNumber }),
                "symbols": password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) })
            ]
            return !passwordRules.values.contains(false)
        }
    }
    
    // Certificate Configuration
    struct CertificateConfig {
        let trustedCertificates: [String]
        let pinnedPublicKeys: [String]
        let allowedIssuers: [String]
        
        static let production = CertificateConfig(
            trustedCertificates: ["EcoSphereRootCA", "EcoSphereIntermediateCA"],
            pinnedPublicKeys: ["public_key_hash_1", "public_key_hash_2"],
            allowedIssuers: ["EcoSphere Exchange CA"]
        )
    }
    
    // API Security
    struct APISecurityConfig {
        let requiresAuthentication: Bool = true
        let requiresEncryption: Bool = true
        let rateLimitRequests: Int = 100
        let rateLimitWindow: TimeInterval = 60
        let apiKeyRotationInterval: TimeInterval = 7_776_000 // 90 days
    }
}

// MARK: - Environment-specific Configuration
extension SecurityConfig {
    static var currentEnvironment: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    enum Environment {
        case development
        case staging
        case production
        
        var securitySettings: SecuritySettings {
            switch self {
            case .development:
                return SecuritySettings()
            case .staging, .production:
                return SecuritySettings()
            }
        }
    }
}
