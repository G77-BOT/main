import Foundation
import Logging

enum ImmediateAction: Codable {
    case isolateSystem
    case notifySecurityTeam
    case initiateForensics
    case deployCountermeasures
    case backupCriticalData
    case lockdownAccess
    case enableQuantumDefense
    case activateEmergencyProtocols
    
    struct ActionPriority {
        let order: Int
        let timeout: TimeInterval
        let retryCount: Int
        
        static func priorityFor(_ action: ImmediateAction) -> ActionPriority {
            switch action {
            case .isolateSystem:
                return ActionPriority(order: 0, timeout: 5, retryCount: 3)
            case .notifySecurityTeam:
                return ActionPriority(order: 1, timeout: 10, retryCount: 5)
            case .initiateForensics:
                return ActionPriority(order: 2, timeout: 15, retryCount: 2)
            case .deployCountermeasures:
                return ActionPriority(order: 3, timeout: 8, retryCount: 4)
            case .backupCriticalData:
                return ActionPriority(order: 4, timeout: 20, retryCount: 3)
            case .lockdownAccess:
                return ActionPriority(order: 5, timeout: 5, retryCount: 2)
            case .enableQuantumDefense:
                return ActionPriority(order: 6, timeout: 12, retryCount: 3)
            case .activateEmergencyProtocols:
                return ActionPriority(order: 7, timeout: 10, retryCount: 4)
            }
        }
    }
    
    func execute() async throws -> ActionResult {
        let priority = ActionPriority.priorityFor(self)
        let executor = ImmediateActionExecutor(action: self, priority: priority)
        return try await executor.executeWithRetry()
    }
    
    var requirements: Set<SystemRequirement> {
        switch self {
        case .isolateSystem:
            return [.networkControl, .processControl]
        case .notifySecurityTeam:
            return [.messaging, .encryption]
        case .initiateForensics:
            return [.storage, .processing, .logging]
        case .deployCountermeasures:
            return [.defense, .monitoring]
        case .backupCriticalData:
            return [.storage, .encryption]
        case .lockdownAccess:
            return [.authentication, .authorization]
        case .enableQuantumDefense:
            return [.quantumProcessor, .encryption]
        case .activateEmergencyProtocols:
            return [.fullSystemAccess, .emergencyControls]
        }
    }
    
    func validate() -> ValidationResult {
        let validator = ImmediateActionValidator(action: self)
        return validator.validate()
    }
    
    func estimateCompletionTime() -> TimeInterval {
        let estimator = CompletionTimeEstimator(action: self)
        return estimator.estimate()
    }
    
    func generateAuditLog() -> AuditEntry {
        return AuditEntry(
            action: self,
            timestamp: Date(),
            priority: ActionPriority.priorityFor(self),
            requirements: requirements
        )
    }
}
