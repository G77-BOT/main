import Foundation
import SecurityProvider

struct ValidationResult {
    let failures: [ValidationFailure]
    
    var isValid: Bool {
        return failures.isEmpty
    }
    
    var primaryFailure: ValidationFailure? {
        return failures.first
    }
    
    var criticalFailures: [ValidationFailure] {
        return failures.filter { $0.isCritical }
    }
    
    func generateReport() -> ValidationReport {
        return ValidationReport(
            timestamp: Date(),
            isValid: isValid,
            failures: failures,
            metadata: createMetadata()
        )
    }
}

enum ValidationFailure: Equatable {
    case osVersionNotMet(required: String)
    case hardwareNotMet(required: [String])
    case processorNotMet(required: [String])
    case memoryNotMet(required: Int64)
    case networkNotAvailable
    case securityPatchMissing
    case backgroundProcessingNotAvailable
    case permissionsNotGranted(missing: [String])
    
    var isCritical: Bool {
        switch self {
        case .osVersionNotMet, .hardwareNotMet, .processorNotMet:
            return true
        case .memoryNotMet, .securityPatchMissing:
            return true
        case .networkNotAvailable, .backgroundProcessingNotAvailable, .permissionsNotGranted:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .osVersionNotMet(let version):
            return "Required iOS version \(version) not met"
        case .hardwareNotMet(let hardware):
            return "Required hardware not available: \(hardware.joined(separator: ", "))"
        case .processorNotMet(let processors):
            return "Required processor not available: \(processors.joined(separator: ", "))"
        case .memoryNotMet(let memory):
            return "Insufficient memory: requires \(ByteCountFormatter.string(fromByteCount: memory, countStyle: .binary))"
        case .networkNotAvailable:
            return "Network connectivity required but not available"
        case .securityPatchMissing:
            return "Required security patch not installed"
        case .backgroundProcessingNotAvailable:
            return "Background processing not available"
        case .permissionsNotGranted(let permissions):
            return "Required permissions not granted: \(permissions.joined(separator: ", "))"
        }
    }
    
    var remediationSteps: [String] {
        switch self {
        case .osVersionNotMet:
            return ["Update iOS to the latest version"]
        case .hardwareNotMet, .processorNotMet:
            return ["This device does not meet minimum hardware requirements"]
        case .memoryNotMet:
            return ["Close background apps", "Free up device memory"]
        case .networkNotAvailable:
            return ["Check network connection", "Connect to Wi-Fi or cellular data"]
        case .securityPatchMissing:
            return ["Install latest security updates"]
        case .backgroundProcessingNotAvailable:
            return ["Enable background app refresh in device settings"]
        case .permissionsNotGranted:
            return ["Grant required permissions in app settings"]
        }
    }
}

struct ValidationReport: Codable {
    let timestamp: Date
    let isValid: Bool
    let failures: [ValidationFailure]
    let metadata: EventMetadata
    
    func logReport() {
        SecurityLogger.shared.logSecurityEvent(SecurityEvent(
            id: UUID(),
            type: .systemAlert,
            severity: failures.contains(where: { $0.isCritical }) ? .high : .medium,
            timestamp: timestamp,
            details: ["validationFailures": failures.map { $0.description }],
            metadata: metadata
        ))
    }
}
