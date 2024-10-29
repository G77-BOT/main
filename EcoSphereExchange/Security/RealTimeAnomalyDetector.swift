import Foundation
import CoreML
import Accelerate
import logging

final class RealTimeAnomalyDetector {
    private let windowSize = 1000
    private let sensitivityThreshold = 0.85
    private var behaviorWindow: [BehaviorMetric] = []
    private let statisticalAnalyzer = StatisticalAnalyzer()
    
    struct AnomalyMetrics {
        let score: Double
        let confidence: Double
        let timestamp: Date
        let affectedMetrics: [String: Double]
    }
    
    // Real-time anomaly detection
    func detectAnomalies(in behavior: SecurityBehavior) async -> Double {
        let currentMetrics = extractMetrics(from: behavior)
        updateBehaviorWindow(with: currentMetrics)
        
        let baselineProfile = await computeBaselineProfile()
        let deviationScore = calculateDeviationScore(
            current: currentMetrics,
            baseline: baselineProfile
        )
        
        if deviationScore > sensitivityThreshold {
            await reportAnomaly(score: deviationScore, metrics: currentMetrics)
        }
        
        return deviationScore
    }
    
    // Statistical analysis of behavior patterns
    private func computeBaselineProfile() async -> BaselineProfile {
        let metrics = behaviorWindow.map { $0.values }
        
        return BaselineProfile(
            mean: statisticalAnalyzer.calculateMean(metrics),
            standardDeviation: statisticalAnalyzer.calculateStandardDeviation(metrics),
            variance: statisticalAnalyzer.calculateVariance(metrics)
        )
    }
    
    // Advanced deviation scoring
    private func calculateDeviationScore(current: BehaviorMetric, baseline: BaselineProfile) -> Double {
        let zScores = calculateZScores(
            values: current.values,
            mean: baseline.mean,
            standardDeviation: baseline.standardDeviation
        )
        
        return normalizeScore(zScores.map { abs($0) }.max() ?? 0)
    }
    
    // Dynamic threshold adjustment
    private func adjustThresholds(based anomalyHistory: [AnomalyMetrics]) {
        let recentAnomalies = anomalyHistory.filter { 
            $0.timestamp > Date().addingTimeInterval(-3600) // Last hour
        }
        
        if recentAnomalies.count > 10 {
            sensitivityThreshold *= 1.1 // Increase threshold by 10%
        } else if recentAnomalies.count < 2 {
            sensitivityThreshold *= 0.9 // Decrease threshold by 10%
        }
    }
    
    // Anomaly reporting and logging
    private func reportAnomaly(score: Double, metrics: BehaviorMetric) async {
        let anomalyMetrics = AnomalyMetrics(
            score: score,
            confidence: calculateConfidence(score),
            timestamp: Date(),
            affectedMetrics: metrics.values
        )
        
        await SecurityLogger.shared.logAnomaly(anomalyMetrics)
        NotificationCenter.default.post(
            name: .anomalyDetected,
            object: nil,
            userInfo: ["metrics": anomalyMetrics]
        )
    }
}

// MARK: - Statistical Analysis
private extension RealTimeAnomalyDetector {
    func calculateZScores(values: [String: Double], mean: [String: Double], standardDeviation: [String: Double]) -> [Double] {
        return values.map { key, value in
            guard let meanValue = mean[key],
                  let stdValue = standardDeviation[key],
                  stdValue > 0 else { return 0 }
            return abs(value - meanValue) / stdValue
        }
    }
    
    func normalizeScore(_ score: Double) -> Double {
        return 1 / (1 + exp(-score))
    }
}
