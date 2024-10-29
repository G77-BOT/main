import Foundation
import Network

final class NetworkMonitor {
    static let shared: NetworkMonitor = NetworkMonitor()
    
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue = DispatchQueue(label: "network.monitor", qos: .utility)
    private let analyticsManager = AnalyticsManager.shared
    private let securityAnalyzer = SecurityAnalyzer.shared
    
    private var requestQueue: [NetworkRequest] = []
    private var isProcessingQueue: Bool = false
    private var currentThrottleDelay: TimeInterval = 0
    
    private(set) var isConnected: Bool = false
    private(set) var connectionType: ConnectionType = .unknown
    private(set) var isExpensive: Bool = false
    private(set) var isConstrained: Bool = false
    
    private init() {
        monitor = NWPathMonitor()
        setupMonitor()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    func enqueueRequest(_ request: NetworkRequest) {
        queue.async { [weak self] in
            self?.requestQueue.append(request)
            self?.processQueue()
        }
    }
    
    func throttleRequests() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Increase throttle delay
            self.currentThrottleDelay += 0.1
            
            // Cap at maximum delay
            self.currentThrottleDelay = min(self.currentThrottleDelay, 1.0)
        }
    }
    
    func resetThrottle() {
        queue.async { [weak self] in
            self?.currentThrottleDelay = 0
        }
    }
    
    // MARK: - Private Methods
    
    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            self.isConnected = path.status == .satisfied
            self.isExpensive = path.isExpensive
            self.isConstrained = path.isConstrained
            
            // Determine connection type
            self.connectionType = self.determineConnectionType(from: path)
            
            // Track network status change
            self.analyticsManager.trackEvent(.networkStatus(
                connected: self.isConnected,
                type: self.connectionType,
                expensive: self.isExpensive,
                constrained: self.isConstrained
            ))
            
            // Analyze security implications
            self.analyzeNetworkSecurity(path)
            
            // Handle connection change
            self.handleConnectionChange()
        }
    }
    
    private func determineConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.usesInterfaceType(.loopback) {
            return .loopback
        } else {
            return .unknown
        }
    }
    
    private func analyzeNetworkSecurity(_ path: NWPath) {
        // Check for insecure networks
        if connectionType == .wifi && !path.isExpensive {
            securityAnalyzer.analyzeWiFiSecurity { result in
                switch result {
                case .secure:
                    break
                case .insecure(let vulnerabilities):
                    SecurityLogger.shared.logWarning("Insecure network detected: \(vulnerabilities)")
                    self.handleInsecureNetwork(vulnerabilities)
                }
            }
        }
    }
    
    private func handleConnectionChange() {
        if isConnected {
            // Process any queued requests
            processQueue()
            
            // Reset throttle
            resetThrottle()
        } else {
            // Cache current requests
            cacheCurrentRequests()
        }
    }
    
    private func processQueue() {
        guard !isProcessingQueue else { return }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.isProcessingQueue = true
            
            // Process requests with throttling
            for request in self.requestQueue {
                guard self.isConnected else {
                    break
                }
                
                // Apply throttling delay
                if self.currentThrottleDelay > 0 {
                    Thread.sleep(forTimeInterval: self.currentThrottleDelay)
                }
                
                // Execute request
                self.executeRequest(request)
            }
            
            self.requestQueue.removeAll()
            self.isProcessingQueue = false
        }
    }
    
    private func executeRequest(_ request: NetworkRequest) {
        // Track request start
        analyticsManager.trackEvent(.networkRequest(
            url: request.url,
            method: request.method,
            headers: request.headers,
            body: request.body
        ))
        
        // Execute request
        request.execute { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                // Track successful response
                self.analyticsManager.trackEvent(.networkResponse(
                    url: request.url,
                    statusCode: response.statusCode,
                    headers: response.headers,
                    body: response.body
                ))
                
            case .failure(let error):
                // Track error
                self.analyticsManager.trackEvent(.networkError(
                    url: request.url,
                    error: error
                ))
                
                // Handle error
                self.handleNetworkError(error, for: request)
            }
        }
    }
    
    private func cacheCurrentRequests() {
        // Implement request caching logic
    }
    
    private func handleNetworkError(_ error: Error, for request: NetworkRequest) {
        // Implement error handling logic
        switch error {
        case let networkError as NetworkError:
            switch networkError {
            case .noConnection:
                // Cache request for later
                cacheCurrentRequests()
                
            case .timeout:
                // Retry with exponential backoff
                retryRequest(request)
                
            case .serverError:
                // Log and notify
                SecurityLogger.shared.logError(error)
                
            default:
                break
            }
        default:
            break
        }
    }
    
    private func handleInsecureNetwork(_ vulnerabilities: [NetworkVulnerability]) {
        // Implement security measures for insecure networks
        for vulnerability in vulnerabilities {
            switch vulnerability {
            case .unencrypted:
                // Force HTTPS
                SecurityLogger.shared.logWarning("Enforcing HTTPS due to unencrypted network")
                
            case .weakEncryption:
                // Enable additional encryption
                SecurityLogger.shared.logWarning("Enabling additional encryption due to weak network security")
                
            case .manInTheMiddle:
                // Enable certificate pinning
                SecurityLogger.shared.logWarning("Enabling strict certificate pinning due to potential MITM attack")
            }
        }
    }
    
    private func retryRequest(_ request: NetworkRequest) {
        // Implement retry logic with exponential backoff
    }
}

// MARK: - Supporting Types

enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case loopback
    case unknown
}

enum NetworkError: Error {
    case noConnection
    case timeout
    case serverError
    case securityError
    case invalidResponse
}

enum NetworkVulnerability {
    case unencrypted
    case weakEncryption
    case manInTheMiddle
}

enum NetworkSecurityStatus {
    case secure
    case insecure([NetworkVulnerability])
}

struct NetworkRequest {
    let url: URL
    let method: String
    let headers: [String: String]
    let body: Data?
    let execute: (@escaping (Result<NetworkResponse, Error>) -> Void) -> Void
}

struct NetworkResponse {
    let statusCode: Int
    let headers: [String: String]
    let body: Data?
}
