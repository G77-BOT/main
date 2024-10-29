import Foundation
import UserNotifications
import SecurityProvider

final class SecurityNotificationService {
    private static let notificationQueue = DispatchQueue(label: "com.ecosphere.security.notifications", qos: .userInitiated)
    private static let retryLimit = 3
    private static let retryDelay: TimeInterval = 5.0
    
    static func send(_ notification: SecurityTeamNotification) async {
        do {
            try await sendNotificationWithRetry(notification)
            await logNotificationSuccess(notification)
        } catch {
            await handleNotificationFailure(notification, error: error)
        }
    }
    
    static func sendBulk(_ notifications: [SecurityTeamNotification]) async {
        await withTaskGroup(of: Void.self) { group in
            for notification in notifications {
                group.addTask {
                    await send(notification)
                }
            }
        }
    }
    
    private static func sendNotificationWithRetry(_ notification: SecurityTeamNotification, attempts: Int = 0) async throws {
        do {
            let payload = try createNotificationPayload(notification)
            try await sendToEndpoint(payload)
        } catch {
            if attempts < retryLimit {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                try await sendNotificationWithRetry(notification, attempts: attempts + 1)
            } else {
                throw SecurityError.notificationDeliveryFailed
            }
        }
    }
    
    private static func createNotificationPayload(_ notification: SecurityTeamNotification) throws -> NotificationPayload {
        return NotificationPayload(
            id: UUID(),
            event: notification.event,
            priority: notification.priority,
            timestamp: notification.timestamp,
            deviceInfo: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            metadata: createMetadata()
        )
    }
}

// MARK: - Helper Methods
private extension SecurityNotificationService {
    static func sendToEndpoint(_ payload: NotificationPayload) async throws {
        let encryptedPayload = try SecurityProvider.shared.encryptSensitiveData(try JSONEncoder().encode(payload))
        
        // Implementation for sending to security endpoint
        let config = NotificationEndpointConfig(
            url: SecurityConfig.notificationEndpoint,
            method: "POST",
            headers: ["X-Security-Token": SecurityProvider.shared.securityToken]
        )
        
        try await NetworkService.sendSecurePayload(encryptedPayload, config: config)
    }
    
    static func logNotificationSuccess(_ notification: SecurityTeamNotification) async {
        await SecurityLogger.shared.logSecurityEvent(SecurityEvent(
            id: UUID(),
            type: .systemAlert,
            severity: .low,
            timestamp: Date(),
            details: ["message": "Security notification sent successfully"],
            metadata: createMetadata()
        ))
    }
    
    static func handleNotificationFailure(_ notification: SecurityTeamNotification, error: Error) async {
        await SecurityLogger.shared.logSecurityEvent(SecurityEvent(
            id: UUID(),
            type: .systemAlert,
            severity: .high,
            timestamp: Date(),
            details: [
                "error": error.localizedDescription,
                "notificationId": notification.event.id.uuidString
            ],
            metadata: createMetadata()
        ))
    }
    
    static func createMetadata() -> EventMetadata {
        return EventMetadata(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        )
    }
}
