import Foundation
import SecurityProvider

final class SecurityConfigurationStore {
    private let queue = DispatchQueue(label: "com.ecosphere.security.config", qos: .userInitiated)
    private let storage = SecureStorage()
    private var cachedConfig: [String: Any] = [:]
    
    struct ConfigurationKey {
        static let environment = "security.environment"
        static let securityLevel = "security.level"
        static let encryptionStrength = "security.encryption.strength"
        static let monitoringInterval = "security.monitoring.interval"
        static let lastUpdate = "security.config.lastUpdate"
    }
    
    func updateConfiguration(_ config: [String: Any]) {
        queue.async {
            self.validateConfiguration(config)
            self.encryptAndStore(config)
            self.updateCache(with: config)
            self.notifyConfigurationUpdate()
        }
    }
    
    func getConfiguration<T>(_ key: String, defaultValue: T) -> T {
        queue.sync {
            if let cachedValue = cachedConfig[key] as? T {
                return cachedValue
            }
            
            guard let storedValue = storage.retrieve(key) as? T else {
                return defaultValue
            }
            
            cachedConfig[key] = storedValue
            return storedValue
        }
    }
    
    func clearConfiguration() {
        queue.async {
            self.storage.clear()
            self.cachedConfig.removeAll()
            self.notifyConfigurationClear()
        }
    }
    
    private func validateConfiguration(_ config: [String: Any]) {
        let validator = ConfigurationValidator()
        guard validator.validate(config) else {
            SecurityLogger.shared.logSecurityEvent(SecurityEvent(
                id: UUID(),
                type: .systemAlert,
                severity: .high,
                timestamp: Date(),
                details: ["error": "Invalid security configuration"],
                metadata: createMetadata()
            ))
            return
        }
    }
    
    private func encryptAndStore(_ config: [String: Any]) {
        do {
            let encryptedConfig = try SecurityProvider.shared.encryptSensitiveData(
                try JSONSerialization.data(withJSONObject: config)
            )
            
            storage.store(
                key: ConfigurationKey.lastUpdate,
                value: Date(),
                options: [.accessibility(.afterFirstUnlock)]
            )
            
            for (key, value) in config {
                storage.store(
                    key: key,
                    value: value,
                    options: [.accessibility(.afterFirstUnlock)]
                )
            }
        } catch {
            handleEncryptionError(error)
        }
    }
    
    private func updateCache(with config: [String: Any]) {
        cachedConfig = config
    }
    
    private func notifyConfigurationUpdate() {
        NotificationCenter.default.post(
            name: .securityConfigurationUpdated,
            object: nil,
            userInfo: ["timestamp": Date()]
        )
    }
    
    private func notifyConfigurationClear() {
        NotificationCenter.default.post(
            name: .securityConfigurationCleared,
            object: nil
        )
    }
    
    private func handleEncryptionError(_ error: Error) {
        SecurityLogger.shared.logSecurityEvent(SecurityEvent(
            id: UUID(),
            type: .systemAlert,
            severity: .critical,
            timestamp: Date(),
            details: ["error": error.localizedDescription],
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
