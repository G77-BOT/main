import Foundation
import Network
import SystemConfiguration


final class ProcessorInformation {
    static let current = ProcessorInformation()
    
    private(set) var processorType: String = {
        return determineProcessorType()
    }()
    
    private(set) var capabilities: ProcessorCapabilities = {
        return detectProcessorCapabilities()
    }()
    
    struct ProcessorCapabilities {
        let supportsNeuralEngine: Bool
        let supportsSecureEnclave: Bool
        let supportsSecurity: Bool
        let supportsAES: Bool
        let supportsQuantumOperations: Bool
        let processorGeneration: ProcessorGeneration
    }
    
    enum ProcessorGeneration: String {
        case legacy
        case modern
        case advanced
        case quantum
        
        var minimumSecurityLevel: SecurityLevel {
            switch self {
            case .legacy: return .basic
            case .modern: return .standard
            case .advanced: return .enhanced
            case .quantum: return .quantum
            }
        }
    }
    
    enum SecurityLevel {
        case basic
        case standard
        case enhanced
        case quantum
        
        var requiredFeatures: [String] {
            switch self {
            case .basic: return ["AES"]
            case .standard: return ["AES", "SecureEnclave"]
            case .enhanced: return ["AES", "SecureEnclave", "NeuralEngine"]
            case .quantum: return ["AES", "SecureEnclave", "NeuralEngine", "QuantumOperations"]
            }
        }
    }
    
    var supportsNeuralEngine: Bool {
        return capabilities.supportsNeuralEngine
    }
    
    var supportsQuantumOperations: Bool {
        return capabilities.supportsQuantumOperations
    }
    
    private static func determineProcessorType() -> String {
        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
    
    private static func detectProcessorCapabilities() -> ProcessorCapabilities {
        let processorType = determineProcessorType()
        
        let generation: ProcessorGeneration
        let supportsNeuralEngine: Bool
        let supportsQuantumOps: Bool
        
        switch processorType {
        case let type where type.contains("ARM64_X8"):
            generation = .quantum
            supportsNeuralEngine = true
            supportsQuantumOps = true
        case let type where type.contains("ARM64"):
            generation = .advanced
            supportsNeuralEngine = true
            supportsQuantumOps = false
        case let type where type.contains("ARM"):
            generation = .modern
            supportsNeuralEngine = false
            supportsQuantumOps = false
        default:
            generation = .legacy
            supportsNeuralEngine = false
            supportsQuantumOps = false
        }
        
        return ProcessorCapabilities(
            supportsNeuralEngine: supportsNeuralEngine,
            supportsSecureEnclave: generation != .legacy,
            supportsSecurity: true,
            supportsAES: true,
            supportsQuantumOperations: supportsQuantumOps,
            processorGeneration: generation
        )
    }
    
    func validateSecurityRequirements(_ level: SecurityLevel) -> Bool {
        let currentFeatures = capabilities.processorGeneration.minimumSecurityLevel.requiredFeatures
        return Set(level.requiredFeatures).isSubset(of: Set(currentFeatures))
    }
    
    func getProcessorSecurityReport() -> ProcessorSecurityReport {
        return ProcessorSecurityReport(
            processorType: processorType,
            capabilities: capabilities,
            securityLevel: capabilities.processorGeneration.minimumSecurityLevel,
            timestamp: Date()
        )
    }
}
