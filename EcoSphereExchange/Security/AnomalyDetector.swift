import Foundation

final class AnomalyDetector {
    static let shared = AnomalyDetector()
    private let analysisEngine = AnalysisEngine.shared
    
    // Configuration
    private let detectionThreshold = SecurityConfig.shared.SecuritySettings().anomalyDetectionThreshold
    private let monitoringInterval = SecurityConfig.shared.SecuritySettings().monitoringInterval
    
    // State
    private var baselineMetrics: [String: BaselineMetric] = [:]
    private var activeMonitors: [UUID: SecurityMonitor] = [:]
    private var anomalyHistory: [UUID: [SecurityAnomaly]] = [:]
    
    // MARK: - Public Interface
    
    func startMonitoring(resourceId: UUID, type: MonitoringType) {
        let monitor = SecurityMonitor(
            resourceId: resourceId,
            type: type,
            interval: monitoringInterval
        )
        activeMonitors[resourceId] = monitor
        
        monitor.startMonitoring { [weak self] metrics in
            self?.processMetrics(metrics, for: resourceId)
        }
    }
    
    func stopMonitoring(resourceId: UUID) {
        activeMonitors[resourceId]?.stopMonitoring()
        activeMonitors.removeValue(forKey: resourceId)
    }
    
    func detectAnomalies(in behavior: UserBehavior) -> [SecurityAnomaly] {
        let analysis = analysisEngine.analyzeBehaviorPattern(behavior)
        
        if analysis.isAnomaly {
            let anomaly = SecurityAnomaly(
                id: UUID(),
                type: .behavioralAnomaly,
                severity: analysis.riskLevel.toSeverity(),
                timestamp: Date(),
                description: "Unusual user behavior detected",
                metadata: [
                    "userId": behavior.userId,
                    "actions": behavior.actions,
                    "deviationScore": analysis.deviationScore
                ]
            )
            recordAnomaly(anomaly, for: UUID(uuidString: behavior.userId) ?? UUID())
            return [anomaly]
        }
        
        return []
    }
    
    func getAnomalyHistory(for resourceId: UUID, timeWindow: TimeInterval? = nil) -> [SecurityAnomaly] {
        guard let anomalies = anomalyHistory[resourceId] else { return [] }
        
        if let window = timeWindow {
            let cutoffDate = Date().addingTimeInterval(-window)
            return anomalies.filter { $0.timestamp > cutoffDate }
        }
        
        return anomalies
    }
    
    // MARK: - Private Implementation
    
    private func processMetrics(_ metrics: SecurityMetrics, for resourceId: UUID) {
        // Update baseline if needed
        if baselineMetrics[resourceId] == nil {
            baselineMetrics[resourceId] = calculateBaseline(from: metrics)
        }
        
        // Detect anomalies
        if let baseline = baselineMetrics[resourceId] {
            let anomalies = detectAnomalies(metrics: metrics, baseline: baseline)
            
            if !anomalies.isEmpty {
                anomalies.forEach { anomaly in
                    recordAnomaly(anomaly, for: resourceId)
                    notifyAnomalyDetected(anomaly)
                }
            }
            
            // Update baseline with new data
            updateBaseline(baseline, with: metrics)
        }
    }
    
    private func calculateBaseline(from metrics: SecurityMetrics) -> BaselineMetric {
        return BaselineMetric(
            mean: metrics.values,
            standardDeviation: [:],
            updateCount: 1,
            lastUpdate: Date()
        )
    }
    
    private func detectAnomalies(metrics: SecurityMetrics, baseline: BaselineMetric) -> [SecurityAnomaly] {
        var anomalies: [SecurityAnomaly] = []
        
        for (key, value) in metrics.values {
            if let meanValue = baseline.mean[key] {
                let deviation = abs(value - meanValue)
                let stdDev = baseline.standardDeviation[key] ?? 1.0
                
                if deviation > (stdDev * detectionThreshold) {
                    let anomaly = SecurityAnomaly(
                        id: UUID(),
                        type: .metricAnomaly,
                        severity: calculateSeverity(deviation: deviation, stdDev: stdDev),
                        timestamp: Date(),
                        description: "Anomaly detected in metric: \(key)",
                        metadata: [
                            "metricName": key,
                            "currentValue": value,
                            "baselineValue": meanValue,
                            "deviation": deviation
                        ]
                    )
                    anomalies.append(anomaly)
                }
            }
        }
        
        return anomalies
    }
    
    private func updateBaseline(_ baseline: BaselineMetric, with metrics: SecurityMetrics) {
        for (key, value) in metrics.values {
            if let currentMean = baseline.mean[key] {
                let newCount = baseline.updateCount + 1
                let weightedValue = (currentMean * Double(baseline.updateCount) + value) / Double(newCount)
                baseline.mean[key] = weightedValue
                
                // Update standard deviation
                let variance = pow(value - weightedValue, 2)
                if let currentStdDev = baseline.standardDeviation[key] {
                    baseline.standardDeviation[key] = sqrt((currentStdDev * currentStdDev * Double(baseline.updateCount) + variance) / Double(newCount))
                } else {
                    baseline.standardDeviation[key] = sqrt(variance)
                }
            } else {
                baseline.mean[key] = value
                baseline.standardDeviation[key] = 0.0
            }
        }
        
        baseline.updateCount += 1
        baseline.lastUpdate = Date()
    }
    
    private func calculateSeverity(deviation: Double, stdDev: Double) -> SecurityEventSeverity {
        let normalizedDeviation = deviation / stdDev
        
        switch normalizedDeviation {
        case 0..<2:
            return .info
        case 2..<3:
            return .warning
        case 3..<4:
            return .error
        default:
            return .critical
        }
    }
    
    private func recordAnomaly(_ anomaly: SecurityAnomaly, for resourceId: UUID) {
        if anomalyHistory[resourceId] == nil {
            anomalyHistory[resourceId] = []
        }
        anomalyHistory[resourceId]?.append(anomaly)
        
        // Cleanup old anomalies
        let retentionPeriod: TimeInterval = 30 * 24 * 60 * 60 // 30 days
        let cutoffDate = Date().addingTimeInterval(-retentionPeriod)
        anomalyHistory[resourceId] = anomalyHistory[resourceId]?.filter { $0.timestamp > cutoffDate }
    }
    
    private func notifyAnomalyDetected(_ anomaly: SecurityAnomaly) {
        // Implement notification logic (e.g., sending to a notification service)
        NotificationCenter.default.post(
            name: .anomalyDetected,
            object: nil,
            userInfo: ["anomaly": anomaly]
        )
    }
}

// MARK: - Supporting Types

struct SecurityMetrics {
    let timestamp: Date
    let values: [String: Double]
    let metadata: [String: Any]
}

class BaselineMetric {
    var mean: [String: Double]
    var standardDeviation: [String: Double]
    var updateCount: Int
    var lastUpdate: Date
    
    init(mean: [String: Double], standardDeviation: [String: Double], updateCount: Int, lastUpdate: Date) {
        self.mean = mean
        self.standardDeviation = standardDeviation
        self.updateCount = updateCount
        self.lastUpdate = lastUpdate
    }
}

enum MonitoringType {
    case system
    case network
    case user
    case application
    case custom(String)
}

extension RiskLevel {
    func toSeverity() -> SecurityEventSeverity {
        switch self {
        case .low:
            return .info
        case .medium:
            return .warning
        case .high:
            return .error
        case .unknown:
            return .warning
        }
    }
}

extension Notification.Name {
    static let anomalyDetected = Notification.Name("AnomalyDetected")
}
