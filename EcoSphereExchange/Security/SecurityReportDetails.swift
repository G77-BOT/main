import Foundation
import SecurityProvider

struct SecurityReportDetails: Codable {
    let report: SecurityReport
    let recommendations: [String]
    let requiredActions: [String]
    let timestamp: Date
    
    var threatAnalysis: ThreatAnalysis {
        ThreatAnalysis(
            vulnerabilities: detectVulnerabilities(),
            anomalies: detectAnomalies(),
            riskScore: calculateRiskScore()
        )
    }
    
    struct ThreatAnalysis: Codable {
        let vulnerabilities: [Vulnerability]
        let anomalies: [Anomaly]
        let riskScore: Double
        
        var requiresImmediate: Bool {
            return vulnerabilities.contains { $0.severity == .critical } ||
                   riskScore > 0.8
        }
    }
    
    struct Vulnerability: Codable {
        let type: VulnerabilityType
        let severity: SeverityLevel
        let description: String
        let mitigation: String
        
        enum VulnerabilityType: String, Codable {
            case jailbreak
            case debugger
            case reverseEngineering
            case emulator
            case invalidSignature
            case systemIntegrity
        }
    }
    
    struct Anomaly: Codable {
        let type: AnomalyType
        let confidence: Double
        let details: String
        let detectionTime: Date
        
        enum AnomalyType: String, Codable {
            case suspiciousActivity
            case unauthorizedAccess
            case dataLeakage
            case malwareIndicator
        }
    }
    
    enum SeverityLevel: String, Codable {
        case low
        case medium
        case high
        case critical
    }
    
    func generatePDFReport() -> Data {
        let reportGenerator = SecurityPDFGenerator(details: self)
        return reportGenerator.generateReport()
    }
    
    func sendToSecurityTeam() async throws {
        let notification = SecurityTeamNotification(
            event: createSecurityEvent(),
            timestamp: timestamp,
            priority: determinePriority(),
            actionRequired: !requiredActions.isEmpty
        )
        
        await SecurityNotificationService.send(notification)
    }
    
    private func detectVulnerabilities() -> [Vulnerability] {
        var vulnerabilities: [Vulnerability] = []
        
        if report.integrityStatus.isJailbroken {
            vulnerabilities.append(Vulnerability(
                type: .jailbreak,
                severity: .critical,
                description: "Device is jailbroken",
                mitigation: "Restore device to factory settings"
            ))
        }
        
        if report.integrityStatus.isDebuggerAttached {
            vulnerabilities.append(Vulnerability(
                type: .debugger,
                severity: .high,
                description: "Debugger detected",
                mitigation: "Disable debugging in production"
            ))
        }
        
        return vulnerabilities
    }
    
    private func detectAnomalies() -> [Anomaly] {
        var anomalies: [Anomaly] = []
        
        if report.securityScore < 70 {
            anomalies.append(Anomaly(
                type: .suspiciousActivity,
                confidence: 0.85,
                details: "Low security score detected",
                detectionTime: timestamp
            ))
        }
        
        return anomalies
    }
    
    private func calculateRiskScore() -> Double {
        return 1.0 - (Double(report.securityScore) / 100.0)
    }
    
    private func createSecurityEvent() -> SecurityEvent {
        return SecurityEvent(
            id: UUID(),
            type: .securityReport,
            severity: report.riskLevel.requiresAction ? .high : .medium,
            timestamp: timestamp,
            details: ["score": report.securityScore],
            metadata: EventMetadata(
                deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                osVersion: report.systemVersion,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            )
        )
    }
    
    private func determinePriority() -> SecurityTeamNotification.NotificationPriority {
        switch report.riskLevel {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low, .minimal: return .low
        }
    }
}
