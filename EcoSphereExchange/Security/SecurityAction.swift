import Foundation
import CryptoKit
import LocalAuthentication
import MetricsKit

enum SecurityAction: Codable {
    case blockAccess(target: SecurityTarget)
    case isolateSystem(scope: IsolationScope)
    case deployCountermeasures(type: CountermeasureType)
    case initiateForensics(level: ForensicsLevel)
    case rotateSecurityKeys(keyTypes: Set<KeyType>)
    case increaseMonitoring(aspects: Set<MonitoringAspect>)
    case restrictNetwork(restrictions: NetworkRestrictions)
    case backupCriticalData(priority: BackupPriority)
    
    struct SecurityTarget: Codable {
        let identifier: String
        let scope: TargetScope
        let duration: TimeInterval
        let reason: String
        
        enum TargetScope: String, Codable {
            case user
            case device
            case network
            case service
            case application
        }
    }
    
    enum IsolationScope: String, Codable {
        case full
        case network
        case process
        case container
        
        var requirements: [IsolationRequirement] {
            switch self {
            case .full: return [.network, .process, .storage, .memory]
            case .network: return [.network, .ports]
            case .process: return [.process, .memory]
            case .container: return [.container, .network, .storage]
            }
        }
    }
    
    enum CountermeasureType: String, Codable {
        case activeDefense
        case deception
        case mitigation
        case prevention
        
        var capabilities: [DefenseCapability] {
            switch self {
            case .activeDefense: return [.block, .track, .counterattack]
            case .deception: return [.honeypot, .misdirection]
            case .mitigation: return [.contain, .reduce]
            case .prevention: return [.detect, .prevent]
            }
        }
    }
    
    enum ForensicsLevel: String, Codable {
        case basic
        case advanced
        case comprehensive
        case realTime
        
        var dataCollectors: [DataCollector] {
            switch self {
            case .basic: return [.logs, .metrics]
            case .advanced: return [.logs, .metrics, .memory, .network]
            case .comprehensive: return [.logs, .metrics, .memory, .network, .storage, .process]
            case .realTime: return [.logs, .metrics, .memory, .network, .storage, .process, .behavioral]
            }
        }
    }
    
    enum KeyType: String, Codable {
        case encryption
        case authentication
        case signing
        case quantum
    }
    
    enum MonitoringAspect: String, Codable {
        case network
        case system
        case user
        case application
        case quantum
    }
    
    struct NetworkRestrictions: Codable {
        let ports: Set<Int>
        let protocols: Set<String>
        let bandwidth: Double
        let duration: TimeInterval
    }
    
    enum BackupPriority: String, Codable {
        case critical
        case high
        case normal
        case low
    }
    
    func execute(context: ExecutionContext) async throws -> ActionResult {
        let executor = ActionExecutor(action: self, context: context)
        return try await executor.execute()
    }
    
    func validate() -> Bool {
        let validator = ActionValidator(action: self)
        return validator.validate()
    }
    
    func estimateImpact() -> ActionImpact {
        let analyzer = ImpactAnalyzer(action: self)
        return analyzer.analyze()
    }
}

// the above code was the original code. Below is the updated code with the new structs and enums
// Added code to represent the result of an action execution
struct ActionResult: Codable {
    let action: SecurityAction
    let status: ActionStatus
    let executionTime: TimeInterval
    let resources: ResourceUsage
}
enum ActionStatus: String, Codable {
    case success
    case failure
}
struct ResourceUsage: Codable {
    let cpu: Double
    let memory: Double
}

