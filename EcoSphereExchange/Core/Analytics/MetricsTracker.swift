import Foundation

class MetricsTracker {
    static let shared = MetricsTracker()
    
    private let queue = DispatchQueue(label: "metrics.queue", qos: .utility)
    private let analyticsManager = AnalyticsManager.shared
    private let performanceOptimizer = PerformanceOptimizer.shared
    private let networkMonitor = NetworkMonitor.shared
    
    private var metrics: [String: [Double]] = [:]
    private var startTimes: [String: Date] = [:]
    
    private init() {
        setupPeriodicReporting()
    }
    
    // MARK: - Public Methods
    
    func trackScreenLoad(screenName: String) {
        startTiming(identifier: "screen_load_\(screenName)")
    }
    
    func trackScreenLoadComplete(screenName: String) {
        let duration = stopTiming(identifier: "screen_load_\(screenName)")
        
        analyticsManager.trackEvent(.performance(
            metric: .screenLoadTime,
            value: duration,
            timestamp: Date()
        ))
    }
    
    func trackNetworkRequest(url: URL, method: String) {
        startTiming(identifier: "network_\(url.absoluteString)")
    }
    
    func trackNetworkResponse(url: URL, method: String, statusCode: Int) {
        let duration = stopTiming(identifier: "network_\(url.absoluteString)")
        
        analyticsManager.trackEvent(.networkRequest(
            url: url,
            method: method,
            statusCode: statusCode,
            duration: duration,
            timestamp: Date()
        ))
    }
    
    func trackMemoryUsage() {
        let memoryUsage = performanceOptimizer.currentMemoryUsage()
        recordMetric("memory_usage", value: memoryUsage)
        
        analyticsManager.trackEvent(.performance(
            metric: .memoryUsage,
            value: memoryUsage,
            timestamp: Date()
        ))
    }
    
    func trackCPUUsage() {
        let cpuUsage = performanceOptimizer.currentCPUUsage()
        recordMetric("cpu_usage", value: cpuUsage)
        
        analyticsManager.trackEvent(.performance(
            metric: .cpuUsage,
            value: cpuUsage,
            timestamp: Date()
        ))
    }
    
    func trackFrameRate() {
        let frameRate = performanceOptimizer.currentFrameRate()
        recordMetric("frame_rate", value: frameRate)
        
        analyticsManager.trackEvent(.performance(
            metric: .frameRate,
            value: frameRate,
            timestamp: Date()
        ))
    }
    
    // MARK: - Private Methods
    
    private func setupPeriodicReporting() {
        // Report metrics every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.reportMetrics()
        }
    }
    
    private func startTiming(identifier: String) {
        queue.async { [weak self] in
            self?.startTimes[identifier] = Date()
        }
    }
    
    private func stopTiming(identifier: String) -> TimeInterval {
        var duration: TimeInterval = 0
        
        queue.sync {
            if let startTime = startTimes[identifier] {
                duration = Date().timeIntervalSince(startTime)
                startTimes.removeValue(forKey: identifier)
            }
        }
        
        return duration
    }
    
    private func recordMetric(_ name: String, value: Double) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if self.metrics[name] == nil {
                self.metrics[name] = []
            }
            
            self.metrics[name]?.append(value)
            
            // Keep only last 100 values
            if self.metrics[name]?.count ?? 0 > 100 {
                self.metrics[name]?.removeFirst()
            }
        }
    }
    
    private func reportMetrics() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            for (name, values) in self.metrics {
                let average = values.reduce(0, +) / Double(values.count)
                
                switch name {
                case "memory_usage":
                    if average > performanceOptimizer.memoryThreshold {
                        self.handleHighMemoryUsage(average)
                    }
                    
                case "cpu_usage":
                    if average > performanceOptimizer.cpuThreshold {
                        self.handleHighCPUUsage(average)
                    }
                    
                case "frame_rate":
                    if average < performanceOptimizer.frameRateThreshold {
                        self.handleLowFrameRate(average)
                    }
                    
                default:
                    break
                }
            }
        }
    }
    
    private func handleHighMemoryUsage(_ usage: Double) {
        SecurityLogger.shared.logWarning("High memory usage detected: \(usage)MB")
        performanceOptimizer.optimizeMemoryUsage()
    }
    
    private func handleHighCPUUsage(_ usage: Double) {
        SecurityLogger.shared.logWarning("High CPU usage detected: \(usage)%")
        performanceOptimizer.optimizeCPUUsage()
    }
    
    private func handleLowFrameRate(_ fps: Double) {
        SecurityLogger.shared.logWarning("Low frame rate detected: \(fps) FPS")
        performanceOptimizer.optimizeFrameRate()
    }
}