import Foundation
import Logging

final class DiskSpaceManager {
    static let shared = DiskSpaceManager()
    private let fileManager = FileManager.default
    private let notificationCenter = NotificationCenter.default
    private let minimumFreeSpace: Int64 = 500_000_000 // 500MB
    
    struct DiskSpaceMetrics {
        let totalSpace: Int64
        let usedSpace: Int64
        let freeSpace: Int64
        let systemFiles: Int64
        let appFiles: Int64
        let timestamp: Date
    }
    
    static var availableSpace: Double {
        return shared.getAvailableSpace()
    }
    
    // Monitor disk space usage
    func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.checkDiskSpace()
        }
    }
    
    // Get current disk space metrics
    func getDiskSpaceMetrics() -> DiskSpaceMetrics {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let path = paths.first else {
            return createEmptyMetrics()
        }
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: path)
            let totalSpace = (attributes[.systemSize] as? NSNumber)?.int64Value ?? 0
            let freeSpace = (attributes[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
            let usedSpace = totalSpace - freeSpace
            
            return DiskSpaceMetrics(
                totalSpace: totalSpace,
                usedSpace: usedSpace,
                freeSpace: freeSpace,
                systemFiles: calculateSystemFilesSize(),
                appFiles: calculateAppFilesSize(),
                timestamp: Date()
            )
        } catch {
            SecurityLogger.shared.logSecurityEvent(createErrorEvent(error))
            return createEmptyMetrics()
        }
    }
    
    // Clean up unnecessary files
    func performCleanup() async throws {
        let metrics = getDiskSpaceMetrics()
        if metrics.freeSpace < minimumFreeSpace {
            try await cleanupTemporaryFiles()
            try await cleanupCacheFiles()
            try await cleanupOldLogs()
        }
    }
}

// MARK: - Private Helper Methods
private extension DiskSpaceManager {
    func getAvailableSpace() -> Double {
        let metrics = getDiskSpaceMetrics()
        return Double(metrics.freeSpace) / Double(metrics.totalSpace)
    }
    
    func checkDiskSpace() {
        let metrics = getDiskSpaceMetrics()
        if metrics.freeSpace < minimumFreeSpace {
            notificationCenter.post(
                name: .lowDiskSpaceWarning,
                object: nil,
                userInfo: ["metrics": metrics]
            )
        }
    }
    
    func calculateSystemFilesSize() -> Int64 {
        // Implementation for system files size calculation
        guard let systemPath = fileManager.urls(for: .libraryDirectory, in: .systemDomainMask).first else {
            return 0
        }
        
        return calculateDirectorySize(at: systemPath)
    }
    
    func calculateAppFilesSize() -> Int64 {
        guard let appPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0
        }
        
        return calculateDirectorySize(at: appPath)
    }
    
    func calculateDirectorySize(at url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var size: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path) else {
                continue
            }
            size += attributes[.size] as? Int64 ?? 0
        }
        
        return size
    }
    
    func cleanupTemporaryFiles() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
        let contents = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
        
        for url in contents {
            try fileManager.removeItem(at: url)
        }
    }
    
    func createEmptyMetrics() -> DiskSpaceMetrics {
        return DiskSpaceMetrics(
            totalSpace: 0,
            usedSpace: 0,
            freeSpace: 0,
            systemFiles: 0,
            appFiles: 0,
            timestamp: Date()
        )
    }
    
    func createErrorEvent(_ error: Error) -> SecurityEvent {
        return SecurityEvent(
            id: UUID(),
            type: .systemAlert,
            severity: .medium,
            timestamp: Date(),
            details: ["error": error.localizedDescription],
            metadata: EventMetadata(
                deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                osVersion: UIDevice.current.systemVersion,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            )
        )
    }
}
