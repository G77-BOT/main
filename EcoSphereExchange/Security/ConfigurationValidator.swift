import Foundation
import Logging

final class ConfigurationValidator {
    private let requiredKeys: Set<String> = [
        "security.environment",
        "security.level",
        "security.encryption.strength",
        "security.monitoring.interval"
    ]
    
    struct ValidationRule {
        let key: String
        let validator: (Any) -> Bool
        let errorMessage: String
    }
    
    private let validationRules: [ValidationRule] = [
        ValidationRule(
            key: "security.environment",
            validator: { value in
                guard let env = value as? String else { return false }
                return ["development", "staging", "production"].contains(env)
            },
            errorMessage: "Invalid environment specified"
        ),
        ValidationRule(
            key: "security.level",
            validator: { value in
                guard let level = value as? String else { return false }
                return ["maximum", "high", "standard"].contains(level)
            },
            errorMessage: "Invalid security level"
        ),
        ValidationRule(
            key: "security.encryption.strength",
            validator: { value in
                guard let strength = value as? Int else { return false }
                return [128, 256, 3392].contains(strength)
            },
            errorMessage: "Invalid encryption strength"
        ),
        ValidationRule(
            key: "security.monitoring.interval",
            validator: { value in
                guard let interval = value as? TimeInterval else { return false }
                return interval >= 1 && interval <= 3600
            },
            errorMessage: "Invalid monitoring interval"
        )
    ]
    
    func validate(_ config: [String: Any]) -> Bool {
        var validationErrors: [String] = []
        
        // Check for required keys
        let missingKeys = requiredKeys.subtracting(config.keys)
        if !missingKeys.isEmpty {
            validationErrors.append("Missing required keys: \(missingKeys.joined(separator: ", "))")
            logValidationError("Missing required configuration keys", missingKeys)
            return false
        }
        
        // Validate each rule
        for rule in validationRules {
            if let value = config[rule.key] {
                if !rule.validator(value) {
                    validationErrors.append("\(rule.key): \(rule.errorMessage)")
                    logValidationError(rule.errorMessage, [rule.key: value])
                }
            }
        }
        
        // Validate dependencies
        if !validateDependencies(config) {
            validationErrors.append("Configuration dependencies validation failed")
        }
        
        // Log validation result
        if !validationErrors.isEmpty {
            logValidationErrors(validationErrors)
            return false
        }
        
        logValidationSuccess(config)
        return true
    }
    
    private func validateDependencies(_ config: [String: Any]) -> Bool {
        guard let securityLevel = config["security.level"] as? String,
              let encryptionStrength = config["security.encryption.strength"] as? Int else {
            return false
        }
        
        switch securityLevel {
        case "maximum":
            return encryptionStrength == 3392
        case "high":
            return encryptionStrength >= 256
        case "standard":
            return encryptionStrength >= 128
        default:
            return false
        }
    }
    
    private func logValidationError(_ message: String, _ details: Any) {
        SecurityLogger.shared.logSecurityEvent(SecurityEvent(
            id: UUID(),
            type: .systemAlert,
            severity: .high,
            timestamp: Date(),
            details: [
                "error": message,
                "details": String(describing: details)
            ],
            metadata: createMetadata()
        ))
    }
    
    private func logValidationErrors(_ errors: [String]) {
        SecurityLogger.shared.logSecurityEvent(SecurityEvent(
            id: UUID(),
            type: .systemAlert,
            severity: .high,
            timestamp: Date(),
            details: ["validationErrors": errors],
            metadata: createMetadata()
        ))
    }
    
    private func logValidationSuccess(_ config: [String: Any]) {
        SecurityLogger.shared.logSecurityEvent(SecurityEvent(
            id: UUID(),
            type: .systemAlert,
            severity: .low,
            timestamp: Date(),
            details: ["message": "Configuration validation successful"],
            metadata: createMetadata()
        ))
    }
    
    private func createMetadata() -> EventMetadata {
        return EventMetadata(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        )
    }
}
