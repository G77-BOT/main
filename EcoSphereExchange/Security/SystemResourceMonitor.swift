import Foundation
import SecurityProvider

final class SystemResourceMonitor {
    static let shared = SystemResourceMonitor()
    private let monitorQueue = DispatchQueue(label: "com.ecosphere.security.resources", qos: .userInitiated)
    private var resourceSnapshots: [ResourceSnapshot] = []
    
    struct ResourceSnapshot: Codable {
        let timestamp: Date
        let cpu: CPUMetrics
        let memory: MemoryMetrics
        let disk: DiskMetrics
        let network: NetworkMetrics
        let quantum: QuantumMetrics?
        
        struct CPUMetrics: Codable {
            let usage: Double
            let temperature: Double
            let frequency: Double
            let cores: Int
            let loadAverage: [Double]
        }
        
        struct MemoryMetrics: Codable {
            let total: UInt64
            let used: UInt64
            let free: UInt64
            let cached: UInt64
            let swapUsed: UInt64
        }
        
        struct DiskMetrics: Codable {
            let total: UInt64
            let used: UInt64
            let free: UInt64
            let readRate: Double
            let writeRate: Double
        }
        
        struct NetworkMetrics: Codable {
            let bytesIn: UInt64
            let bytesOut: UInt64
            let packetsIn: UInt64
            let packetsOut: UInt64
            let errors: UInt64
        }
        
        struct QuantumMetrics: Codable {
            let qubits: Int
            let coherenceTime: TimeInterval
            let errorRate: Double
            let entanglementQuality: Double
        }
    }
    
    var availableResources: ResourceAvailability {
        return calculateResourceAvailability()
    }
    
    func startMonitoring(interval: TimeInterval = 1.0) {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.captureResourceSnapshot()
        }
    }
    
    private func captureResourceSnapshot() {
        let snapshot = ResourceSnapshot(
            timestamp: Date(),
            cpu: captureCPUMetrics(),
            memory: captureMemoryMetrics(),
            disk: captureDiskMetrics(),
            network: captureNetworkMetrics(),
            quantum: captureQuantumMetrics()
        )
        
        monitorQueue.async {
            self.resourceSnapshots.append(snapshot)
            self.pruneOldSnapshots()
            self.analyzeResourceTrends()
        }
    }
    
    private func calculateResourceAvailability() -> ResourceAvailability {
        let calculator = ResourceCalculator(snapshots: resourceSnapshots)
        return calculator.calculateAvailability()
    }
    
    func generateResourceReport() -> ResourceReport {
        return ResourceReport(
            snapshots: resourceSnapshots,
            availability: availableResources,
            trends: analyzeResourceTrends(),
            recommendations: generateRecommendations()
        )
    }
    
    private func analyzeResourceTrends() -> ResourceTrends {
        let analyzer = ResourceTrendAnalyzer(snapshots: resourceSnapshots)
        return analyzer.analyzeTrends()
    }
    
    private func generateRecommendations() -> [ResourceRecommendation] {
        let recommendationEngine = ResourceRecommendationEngine(
            snapshots: resourceSnapshots,
            trends: analyzeResourceTrends()
        )
        return recommendationEngine.generateRecommendations()
    }
    
    private func pruneOldSnapshots() {
        let cutoffDate = Calendar.current.date(byAddingMinutes: -30, to: Date()) ?? Date()
        resourceSnapshots = resourceSnapshots.filter { $0.timestamp >= cutoffDate }
    }
}
