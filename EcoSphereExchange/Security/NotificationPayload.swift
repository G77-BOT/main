import Foundation
import Logging

struct NotificationPayload: Codable {
    let id: UUID
    let event: SecurityEvent
    let priority: SecurityTeamNotification.NotificationPriority
    let timestamp: Date
    let deviceInfo: String
    let metadata: EventMetadata
    
    // Additional payload data
    var securityContext: SecurityContext {
        SecurityContext(
            threatLevel: calculateThreatLevel(),
            environmentData: gatherEnvironmentData(),
            systemState: captureSystemState()
        )
    }
    
    struct SecurityContext: Codable {
        let threatLevel: ThreatLevel
        let environmentData: EnvironmentData
        let systemState: SystemState
        let correlationId: String
        
        init(threatLevel: ThreatLevel, environmentData: EnvironmentData, systemState: SystemState) {
            self.threatLevel = threatLevel
            self.environmentData = environmentData
            self.systemState = systemState
            self.correlationId = UUID().uuidString
        }
    }
    
    struct EnvironmentData: Codable {
        let networkStatus: String
        let batteryLevel: Float
        let diskSpace: Double
        let memoryUsage: Double
        let timestamp: Date
    }
    
    struct SystemState: Codable {
        let isJailbroken: Bool
        let integrityValidated: Bool
        let securityPatchLevel: String
        let activeSecurityCountermeasures: [String]
    }
    
    enum ThreatLevel: String, Codable {
        case critical
        case high
        case medium
        case low
        case none
    }
}

// MARK: - Private Helper Methods
private extension NotificationPayload {
    func calculateThreatLevel() -> ThreatLevel {
        switch event.severity {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
    
    func gatherEnvironmentData() -> EnvironmentData {
        return EnvironmentData(
            networkStatus: NetworkMonitor.shared.currentStatus.rawValue,
            batteryLevel: UIDevice.current.batteryLevel,
            diskSpace: DiskSpaceManager.availableSpace,
            memoryUsage: ProcessInfo.processInfo.systemUptime,
            timestamp: Date()
        )
    }
    
    func captureSystemState() -> SystemState {
        return SystemState(
            isJailbroken: SecurityProvider.shared.isJailbroken,
            integrityValidated: SecurityProvider.shared.validateSystemIntegrity(),
            securityPatchLevel: SecurityProvider.shared.currentPatchLevel,
            activeSecurityCountermeasures: SecurityProvider.shared.activeCountermeasures
        )
    }
}
