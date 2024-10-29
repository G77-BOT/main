import Foundation
import CryptoKit
import LocalAuthentication
import MetricsKit

struct SecurityAnomaly: Identifiable, Codable {
    let id: UUID
    let type: AnomalyType
    let severity: SeverityLevel
    let timestamp: Date
    let source: AnomalySource
    let details: AnomalyDetails
    let confidence: Double
    
    enum AnomalyType: String, Codable {
        case behavioralDeviation
        case unauthorizedAccess
        case maliciousActivity
        case dataExfiltration
        case systemManipulation
        case networkAnomaly
        case cryptographicFailure
        case integrityViolation
        
        var category: AnomalyCategory {
            switch self {
            case .behavioralDeviation, .unauthorizedAccess:
                return .userBehavior
            case .maliciousActivity, .systemManipulation:
                return .systemSecurity
            case .dataExfiltration, .networkAnomaly:
                return .networkSecurity
            case .cryptographicFailure, .integrityViolation:
                return .dataProtection
            }
        }
    }
    
    enum AnomalyCategory: String, Codable {
        case userBehavior
        case systemSecurity
        case networkSecurity
        case dataProtection
    }
    
    enum AnomalySource: String, Codable {
        case neuralNetwork
        case behavioralAnalysis
        case systemMonitor
        case networkTraffic
        case integrityCheck
        case quantumDetector
    }
    
    struct AnomalyDetails: Codable {
        let description: String
        let indicators: [String]
        let affectedComponents: [String]
        let potentialImpact: String
        let detectionMethod: String
        let falsePositiveProbability: Double
    }
    
    var requiresImmediateAction: Bool {
        return severity == .critical || 
               confidence > 0.9 ||
               type == .dataExfiltration
    }
    
    func generateResponse() -> AnomalyResponse {
        return AnomalyResponse(
            anomaly: self,
            recommendedActions: determineActions(),
            mitigationSteps: generateMitigationSteps(),
            preventiveMeasures: recommendPreventiveMeasures()
        )
    }
    
    private func determineActions() -> [SecurityAction] {
        switch type {
        case .unauthorizedAccess, .dataExfiltration:
            return [.blockAccess, .alertSecurityTeam, .initiateForensics]
        case .maliciousActivity, .systemManipulation:
            return [.isolateSystem, .deployCountermeasures, .increaseMonitoring]
        case .networkAnomaly:
            return [.restrictNetwork, .analyzeTraffic, .updateFirewall]
        case .cryptographicFailure:
            return [.rotateKeys, .validateCertificates, .enhanceEncryption]
        case .integrityViolation:
            return [.verifyIntegrity, .restoreBackup, .auditSystem]
        case .behavioralDeviation:
            return [.flagForReview, .increaseAuthentication, .logActivity]
        }
    }
    
    private func generateMitigationSteps() -> [MitigationStep] {
        return MitigationStrategy(anomalyType: type)
            .generateSteps(severity: severity)
    }
    
    private func recommendPreventiveMeasures() -> [PreventiveMeasure] {
        return PreventiveStrategy(
            anomalyType: type,
            severity: severity,
            source: source
        ).generateMeasures()
    }
}
