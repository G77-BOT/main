import Foundation
import UIKit
import Network

struct EventMetadata: Codable {
    // Device Information
    let deviceId: String
    let deviceModel: String
    let osVersion: String
    let appVersion: String
    
    // Network Information
    let networkStatus: NetworkStatus
    let ipAddress: String?
    let vpnStatus: Bool
    
    // Application State
    let timestamp: Date
    let processId: Int32
    let memoryUsage: Double
    let diskSpace: Double
    
    // Security Context
    let securityPatchLevel: String
    let jailbreakStatus: Bool
    let lastSecurityScan: Date
    
    init(deviceId: String, osVersion: String, appVersion: String) {
        self.deviceId = deviceId
        self.deviceModel = UIDevice.current.model
        self.osVersion = osVersion
        self.appVersion = appVersion
        
        // Network information
        self.networkStatus = NetworkMonitor.shared.currentStatus
        self.ipAddress = NetworkMonitor.shared.currentIPAddress
        self.vpnStatus = NetworkMonitor.shared.isVPNActive
        
        // System metrics
        self.timestamp = Date()
        self.processId = ProcessInfo.processInfo.processIdentifier
        self.memoryUsage = ProcessInfo.processInfo.systemUptime
        self.diskSpace = DiskSpaceManager.availableSpace
        
        // Security information
        self.securityPatchLevel = SecurityProvider.shared.currentPatchLevel
        self.jailbreakStatus = SecurityProvider.shared.isJailbroken
        self.lastSecurityScan = SecurityProvider.shared.lastScanDate
    }
    
    // Custom encoding for sensitive data
    enum CodingKeys: String, CodingKey {
        case deviceId, deviceModel, osVersion, appVersion
        case networkStatus, ipAddress, vpnStatus
        case timestamp, processId, memoryUsage, diskSpace
        case securityPatchLevel, jailbreakStatus, lastSecurityScan
    }
}
