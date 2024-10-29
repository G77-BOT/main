import Foundation


enum PrioritizedAction: Codable {
    case increaseMonitoring
    case restrictAccess
    case analyzePatterns
    case updateDefenses
    case scanVulnerabilities
    case reinforceEncryption
    case deployHoneypots
    case enhanceAuthentication
    
    struct Priority: Comparable {
        let level: Int
        let urgency: Urgency
        let impact: Impact
        
        enum Urgency: Int {
            case critical = 0
            case high = 1
            case medium = 2
            case low = 3
        }
        
        enum Impact: Int {
            case severe = 0
            case major = 1
            case moderate = 2
            case minor = 3
        }
        
        static func < (lhs: Priority, rhs: Priority) -> Bool {
            if lhs.level != rhs.level {
                return lhs.level < rhs.level
            }
            if lhs.urgency.rawValue != rhs.urgency.rawValue {
                return lhs.urgency.rawValue < rhs.urgency.rawValue
            }
            return lhs.impact.rawValue < rhs.impact.rawValue
        }
    }
    
    var priority: Priority {
        switch self {
        case .increaseMonitoring:
            return Priority(level: 1, urgency: .high, impact: .major)
        case .restrictAccess:
            return Priority(level: 1, urgency: .critical, impact: .severe)
        case .analyzePatterns:
            return Priority(level: 2, urgency: .medium, impact: .moderate)
        case .updateDefenses:
            return Priority(level: 2, urgency: .high, impact: .major)
        case .scanVulnerabilities:
            return Priority(level: 3, urgency: .medium, impact: .major)
        case .reinforceEncryption:
            return Priority(level: 2, urgency: .high, impact: .severe)
        case .deployHoneypots:
            return Priority(level: 3, urgency: .medium, impact: .moderate)
        case .enhanceAuthentication:
            return Priority(level: 2, urgency: .high, impact: .major)
        }
    }
    
    func execute() async throws -> ActionResult {
        let executor = PrioritizedActionExecutor(action: self)
        return try await executor.executeWithPriority()
    }
    
    var resourceRequirements: ResourceRequirements {
        switch self {
        case .increaseMonitoring:
            return ResourceRequirements(
                computational: .init(cpuCores: 2, gpuCores: nil, quantumUnits: nil, processingPower: 1000, utilizationTarget: 0.7),
                memory: .init(ramRequired: 1024 * 1024 * 100, bufferSize: 1024 * 1024, cacheSize: 1024 * 1024 * 10, swapSpace: 1024 * 1024 * 50, priorityLevel: .high),
                storage: .init(persistentStorage: 1024 * 1024 * 500, temporaryStorage: 1024 * 1024 * 100, backupStorage: 1024 * 1024 * 200, encryptionOverhead: 0.1, redundancyFactor: 2),
                network: .init(bandwidth: 100 * 1024 * 1024, latencyRequirement: 0.1, concurrentConnections: 100, encryptedChannels: 10, redundantPaths: 2)
            )
        // Add similar resource requirements for other cases
        default:
            return ResourceRequirements.default
        }
    }
    
    func validate() -> ValidationResult {
        let validator = PrioritizedActionValidator(action: self)
        return validator.validate()
    }
    
    func generateMetrics() -> ActionMetrics {
        return ActionMetrics(
            action: self,
            priority: priority,
            resources: resourceRequirements,
            timestamp: Date()
        )
    }
}


// the code below is added and the above code was the original code from the original implementation.
struct ResourceRequirements: Codable {
    let computational: ComputationalResources
    let memory: MemoryResources
    let storage: StorageResources
    let network: NetworkResources
}
struct ComputationalResources: Codable {
    let cpuCores: Int
    let gpuCores: Int?
    let quantumUnits: Int?
    let processingPower: Double
    let utilizationTarget: Double
}
struct MemoryResources: Codable {
    let ramRequired: Double
    let bufferSize: Double
    let cacheSize: Double
    let swapSpace: Double
    let priorityLevel: PrioritizedAction.Priority
}
struct StorageResources: Codable {
    let persistentStorage: Double
    let temporaryStorage: Double
    let backupStorage: Double
    let encryptionOverhead: Double
    let redundancyFactor: Int
}
struct NetworkResources: Codable {
    let bandwidth: Double
    let latencyRequirement: Double
    let concurrentConnections: Int
    let encryptedChannels: Int
    let redundantPaths: Int
}
