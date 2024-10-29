import Foundation
import CryptoKit
import LocalAuthentication
import MetricsKit
extension Notification.Name {
    static let securityEventOccurred = Notification.Name("securityEventOccurred")
    static let anomalyDetected = Notification.Name("anomalyDetected")
    static let threatDetected = Notification.Name("threatDetected")
    static let adminSessionTerminated = Notification.Name("adminSessionTerminated")
    static let lowDiskSpaceWarning = Notification.Name("lowDiskSpaceWarning")
}

final class SecurityEventNotifier {
    static let shared = SecurityEventNotifier()
    private let notificationCenter = NotificationCenter.default
    
    func registerForSecurityEvents(_ observer: Any, selector: Selector) {
        notificationCenter.addObserver(
            observer,
            selector: selector,
            name: .securityEventOccurred,
            object: nil
        )
    }
    
    func postSecurityEvent(_ event: SecurityEvent) {
        notificationCenter.post(
            name: .securityEventOccurred,
            object: nil,
            userInfo: ["event": event]
        )
        
        handleCriticalEvents(event)
    }
    
    private func handleCriticalEvents(_ event: SecurityEvent) {
        if event.severity == .critical {
            Task {
                await SecurityProvider.shared.initiateSystemLockdown()
                await notifySecurityTeam(event)
            }
        }
    }
    
    private func notifySecurityTeam(_ event: SecurityEvent) async {
        // Implementation for security team notification
        let notification = SecurityTeamNotification(
            event: event,
            timestamp: Date(),
            priority: .high,
            actionRequired: true
        )
        
        await SecurityNotificationService.send(notification)
    }
}

// MARK: - Security Team Notification
struct SecurityTeamNotification {
    let event: SecurityEvent
    let timestamp: Date
    let priority: NotificationPriority
    let actionRequired: Bool
    
    enum NotificationPriority {
        case low
        case medium
        case high
        case critical
    }
}
