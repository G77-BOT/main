import Foundation
import SecurityProvider
@available(iOS 15.0, *)

struct SecurityReport: Codable {
    let timestamp: Date
    let deviceModel: String
    let systemVersion: String
    let securityFeatures: [DeviceCapabilities.SecurityFeature: Bool]
    let hardwareCapabilities: DeviceCapabilities.HardwareCapabilities
    let integrityStatus: IntegrityStatus
    
    struct IntegrityStatus: Codable {
        let isJailbroken: Bool
        let isDebuggerAttached: Bool
        let isReverseEngineered: Bool
        let isEmulator: Bool
        let hasValidSignature: Bool
        let systemIntegrityValid: Bool
    }
    
    var securityScore: Int {
        var score = 100
        
        // Deduct points for security vulnerabilities
        if integrityStatus.isJailbroken { score -= 40 }
        if integrityStatus.isDebuggerAttached { score -= 30 }
        if integrityStatus.isReverseEngineered { score -= 35 }
        if integrityStatus.isEmulator { score -= 25 }
        if !integrityStatus.hasValidSignature { score -= 35 }
        if !integrityStatus.systemIntegrityValid { score -= 30 }
        
        // Deduct points for missing security features
        securityFeatures.forEach { feature, enabled in
            if !enabled {
                switch feature {
                case .secureEnclave: score -= 20
                case .keychain: score -= 15
                case .biometrics: score -= 10
                case .appDataProtection: score -= 15
                case .secureBootchain: score -= 15
                }
            }
        }
        
        return max(0, score)
    }
    
    var riskLevel: RiskLevel {
        switch securityScore {
        case 90...100: return .minimal
        case 70..<90: return .low
        case 50..<70: return .medium
        case 30..<50: return .high
        default: return .critical
        }
    }
    
    enum RiskLevel: String, Codable {
        case minimal
        case low
        case medium
        case high
        case critical
        
        var requiresAction: Bool {
            return self == .high || self == .critical
        }
    }
    
    func generateDetailedReport() -> SecurityReportDetails {
        return SecurityReportDetails(
            report: self,
            recommendations: generateRecommendations(),
            requiredActions: generateRequiredActions(),
            timestamp: Date()
        )
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if !securityFeatures[.biometrics, default: false] {
            recommendations.append("Enable biometric authentication for enhanced security")
        }
        
        if !securityFeatures[.appDataProtection, default: false] {
            recommendations.append("Enable complete data protection")
        }
        
        if integrityStatus.isDebuggerAttached {
            recommendations.append("Disable debugging in production environment")
        }
        
        return recommendations
    }
    
    private func generateRequiredActions() -> [String] {
        var actions: [String] = []
        
        if integrityStatus.isJailbroken {
            actions.append("Device must be restored to factory settings")
        }
        
        if !integrityStatus.hasValidSignature {
            actions.append("Reinstall application from official source")
        }
        
        if !integrityStatus.systemIntegrityValid {
            actions.append("System integrity check failed - contact support")
        }
        
        return actions
    }
}
