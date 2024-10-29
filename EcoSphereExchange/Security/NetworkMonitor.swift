import Foundation
import Network
import SystemConfiguration
import Logging

final class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.ecosphere.networkmonitor")
    
    private(set) var currentStatus: NetworkStatus = .unknown
    private(set) var isVPNActive = false
    private(set) var currentIPAddress: String?
    private var connectionObservers: [UUID: (NetworkStatus) -> Void] = [:]
    
    enum NetworkStatus: String {
        case wifi
        case cellular
        case ethernet
        case vpn
        case offline
        case unknown
    }
    
    init() {
        setupNetworkMonitoring()
        startVPNMonitoring()
        startIPAddressMonitoring()
    }
    
    // Network path monitoring
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            let status = self.determineNetworkStatus(from: path)
            self.currentStatus = status
            
            self.notifyObservers(of: status)
            self.logNetworkChange(status)
            
            if path.status == .satisfied {
                self.performSecurityCheck(for: path)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    // VPN status monitoring
    private func startVPNMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkVPNStatus()
        }
    }
    
    // IP address monitoring
    private func startIPAddressMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateIPAddress()
        }
    }
    
    // Network security check
    private func performSecurityCheck(for path: NWPath) {
        let interfaces = path.availableInterfaces
        
        for interface in interfaces {
            if interface.type == .cellular {
                checkCellularSecurity(interface)
            } else if interface.type == .wifi {
                checkWiFiSecurity(interface)
            }
        }
    }
    
    // Observer pattern implementation
    func addObserver(_ observer: @escaping (NetworkStatus) -> Void) -> UUID {
        let id = UUID()
        connectionObservers[id] = observer
        return id
    }
    
    func removeObserver(id: UUID) {
        connectionObservers.removeValue(forKey: id)
    }
}

// MARK: - Private Helper Methods
private extension NetworkMonitor {
    func determineNetworkStatus(from path: NWPath) -> NetworkStatus {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
        if isVPNActive { return .vpn }
        if path.status == .unsatisfied { return .offline }
        return .unknown
    }
    
    func checkVPNStatus() {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return
        }
        
        let isVPN = flags.contains(.reachable) && flags.contains(.transientConnection)
        if isVPN != self.isVPNActive {
            self.isVPNActive = isVPN
            notifyObservers(of: isVPN ? .vpn : currentStatus)
        }
    }
    
    func updateIPAddress() {
        // Implementation for IP address detection
        DispatchQueue.global().async {
            if let address = self.getIPAddress() {
                DispatchQueue.main.async {
                    self.currentIPAddress = address
                }
            }
        }
    }
    
    func notifyObservers(of status: NetworkStatus) {
        connectionObservers.values.forEach { $0(status) }
    }
    
    func logNetworkChange(_ status: NetworkStatus) {
        SecurityLogger.shared.logSecurityEvent(SecurityEvent(
            id: UUID(),
            type: .systemAlert,
            severity: .medium,
            timestamp: Date(),
            details: ["networkStatus": status.rawValue],
            metadata: EventMetadata(
                deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                osVersion: UIDevice.current.systemVersion,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            )
        ))
    }
}
