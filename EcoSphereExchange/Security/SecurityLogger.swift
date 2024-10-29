import Foundation
import os.log
import SecurityProvider

final class SecurityLogger {
    static let shared = SecurityLogger()
    private let logger = Logger(subsystem: "com.ecosphere.exchange", category: "security")
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.ecosphere.security.logging")
    
    struct SecurityEvent: Codable {
        let id: UUID
        let type: EventType
        let severity: EventSeverity
        let timestamp: Date
        let details: [String: String]
        let metadata: EventMetadata
    }
    
    enum EventType: String, Codable {
        case anomalyDetected
        case threatIdentified
        case authenticationFailure
        case unauthorizedAccess
        case securityBreach
        case systemAlert
    }
    
    enum EventSeverity: Int, Codable {
        case critical = 4
        case high = 3
        case medium = 2
        case low = 1
    }
    
    // Log security events with encryption
    func logSecurityEvent(_ event: SecurityEvent) async {
        queue.async {
            self.logger.log(level: self.getLogLevel(for: event.severity),
                          "Security Event: \(event.type.rawValue), Severity: \(event.severity)")
            
            self.writeToSecureFile(event)
            self.notifySecurityTeam(if: event.severity == .critical)
        }
    }
    
    // Log anomaly detection
    func logAnomaly(_ metrics: AnomalyMetrics) async {
        let event = SecurityEvent(
            id: UUID(),
            type: .anomalyDetected,
            severity: determineSeverity(from: metrics),
            timestamp: Date(),
            details: ["score": String(metrics.score),
                     "confidence": String(metrics.confidence)],
            metadata: createMetadata()
        )
        
        await logSecurityEvent(event)
    }
    
    // Secure file writing
    private func writeToSecureFile(_ event: SecurityEvent) {
        guard let logDirectory = getSecureLogDirectory() else { return }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(event)
            let encryptedData = try SecurityProvider.shared.encryptSensitiveData(data)
            let filename = "\(event.timestamp.timeIntervalSince1970)-\(event.id).secure"
            let fileURL = logDirectory.appendingPathComponent(filename)
            
            try encryptedData.ciphertext.write(to: fileURL, options: .completeFileProtection)
        } catch {
            logger.error("Failed to write security log: \(error.localizedDescription)")
        }
    }
    
    // Secure log rotation
    private func rotateLogFiles() {
        guard let logDirectory = getSecureLogDirectory() else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: logDirectory,
                                                          includingPropertiesForKeys: [.creationDateKey])
            let oldFiles = files.filter { file in
                guard let creation = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate else {
                    return false
                }
                return Date().timeIntervalSince(creation) > (7 * 24 * 3600) // 7 days
            }
            
            try oldFiles.forEach { try fileManager.removeItem(at: $0) }
        } catch {
            logger.error("Log rotation failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Helper Methods
private extension SecurityLogger {
    func getLogLevel(for severity: EventSeverity) -> OSLogType {
        switch severity {
        case .critical: return .fault
        case .high: return .error
        case .medium: return .info
        case .low: return .debug
        }
    }
    
    func getSecureLogDirectory() -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let logDirectory = documentsDirectory.appendingPathComponent("SecureLogs")
        
        do {
            try fileManager.createDirectory(at: logDirectory,
                                         withIntermediateDirectories: true,
                                         attributes: [.protectionKey: FileProtectionType.complete])
            return logDirectory
        } catch {
            logger.error("Failed to create secure log directory: \(error.localizedDescription)")
            return nil
        }
    }
    
    func determineSeverity(from metrics: AnomalyMetrics) -> EventSeverity {
        switch metrics.score {
        case 0.9...: return .critical
        case 0.7...: return .high
        case 0.5...: return .medium
        default: return .low
        }
    }
    
    func createMetadata() -> EventMetadata {
        return EventMetadata(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        )
    }
}
