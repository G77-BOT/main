import Foundation
import SecurityProvider

struct SecurityResponse {
    let status: SecurityStatus
    let threatLevel: ThreatLevel
    let timestamp: Date
    let details: SecurityDetails
    
    init(status: SecurityStatus, threatLevel: ThreatLevel, timestamp: Date) {
        self.status = status
        self.threatLevel = threatLevel
        self.timestamp = timestamp
        self.details = SecurityDetails(
            anomalies: detectAnomalies(),
            vulnerabilities: assessVulnerabilities(),
            recommendations: generateRecommendations()
        )
    }
    
    enum SecurityStatus {
        case secure
        case suspicious
        case compromised
        case critical
        
        var requiresAction: Bool {
            switch self {
            case .secure: return false
            case .suspicious, .compromised, .critical: return true
            }
        }
    }
    
    struct SecurityDetails {
        let anomalies: [SecurityAnomaly]
        let vulnerabilities: [Vulnerability]
        let recommendations: [SecurityRecommendation]
        
        var hasCriticalIssues: Bool {
            return anomalies.contains { $0.severity == .critical } ||
                   vulnerabilities.contains { $0.severity == .critical }
        }
    }
    
    var securityScore: Int {
        var score = 100
        
        score -= threatLevel.riskFactor
        score -= details.anomalies.reduce(0) { $0 + $1.severity.impactScore }
        score -= details.vulnerabilities.reduce(0) { $0 + $1.severity.impactScore }
        
        return max(0, score)
    }
    
    func generateReport() -> SecurityReport {
        return SecurityReport(
            response: self,
            recommendations: details.recommendations,
            timestamp: timestamp,
            metadata: createMetadata()
        )
    }
    
    private func detectAnomalies() -> [SecurityAnomaly] {
        let detector = AnomalyDetector()
        return detector.detectAnomalies()
    }
    
    private func assessVulnerabilities() -> [Vulnerability] {
        let scanner = VulnerabilityScanner()
        return scanner.performScan()
    }
    
    private func generateRecommendations() -> [SecurityRecommendation] {
        let analyzer = SecurityAnalyzer()
        return analyzer.generateRecommendations(
            basedOn: status,
            threatLevel: threatLevel
        )
    }
    
    private func createMetadata() -> SecurityMetadata {
        return SecurityMetadata(
            deviceInfo: DeviceInfo.current,
            systemStatus: SystemStatus.current,
            timestamp: timestamp
        )
    }
}
