import Foundation
import Accelerate

final class StatisticalAnalyzer {
    private let minimumSampleSize = 30
    private let confidenceInterval = 0.95
    
    struct StatisticalMetrics {
        let mean: Double
        let median: Double
        let standardDeviation: Double
        let variance: Double
        let skewness: Double
        let kurtosis: Double
        let confidenceBounds: ConfidenceBounds
    }
    
    struct ConfidenceBounds {
        let upper: Double
        let lower: Double
    }
    
    // Calculate comprehensive statistical metrics
    func calculateMetrics(for data: [[String: Double]]) -> [String: StatisticalMetrics] {
        var metrics: [String: StatisticalMetrics] = [:]
        
        let keys = Set(data.flatMap { $0.keys })
        for key in keys {
            let values = data.compactMap { $0[key] }
            guard values.count >= minimumSampleSize else { continue }
            
            metrics[key] = StatisticalMetrics(
                mean: calculateMean(values),
                median: calculateMedian(values),
                standardDeviation: calculateStandardDeviation(values),
                variance: calculateVariance(values),
                skewness: calculateSkewness(values),
                kurtosis: calculateKurtosis(values),
                confidenceBounds: calculateConfidenceBounds(values)
            )
        }
        
        return metrics
    }
    
    // Calculate mean using Accelerate framework for performance
    func calculateMean(_ values: [Double]) -> Double {
        var result = 0.0
        vDSP_meanvD(values, 1, &result, vDSP_Length(values.count))
        return result
    }
    
    // Calculate median
    func calculateMedian(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let count = values.count
        if count % 2 == 0 {
            return (sorted[count/2 - 1] + sorted[count/2]) / 2
        } else {
            return sorted[count/2]
        }
    }
    
    // Calculate standard deviation using Accelerate
    func calculateStandardDeviation(_ values: [Double]) -> Double {
        let mean = calculateMean(values)
        var squaredDifferences = values.map { pow($0 - mean, 2) }
        var variance = 0.0
        vDSP_meanvD(&squaredDifferences, 1, &variance, vDSP_Length(values.count))
        return sqrt(variance)
    }
    
    // Calculate variance
    func calculateVariance(_ values: [Double]) -> Double {
        let standardDeviation = calculateStandardDeviation(values)
        return pow(standardDeviation, 2)
    }
    
    // Calculate skewness for distribution analysis
    private func calculateSkewness(_ values: [Double]) -> Double {
        let mean = calculateMean(values)
        let std = calculateStandardDeviation(values)
        let n = Double(values.count)
        
        let cubedZScores = values.map { pow(($0 - mean) / std, 3) }
        return (n * cubedZScores.reduce(0, +)) / ((n - 1) * (n - 2))
    }
    
    // Calculate kurtosis for peak analysis
    private func calculateKurtosis(_ values: [Double]) -> Double {
        let mean = calculateMean(values)
        let std = calculateStandardDeviation(values)
        let n = Double(values.count)
        
        let fourthPowerZScores = values.map { pow(($0 - mean) / std, 4) }
        return (n * (n + 1) * fourthPowerZScores.reduce(0, +)) / 
              ((n - 1) * (n - 2) * (n - 3)) - 
              (3 * pow(n - 1, 2)) / ((n - 2) * (n - 3))
    }
    
    // Calculate confidence bounds
    private func calculateConfidenceBounds(_ values: [Double]) -> ConfidenceBounds {
        let mean = calculateMean(values)
        let std = calculateStandardDeviation(values)
        let n = Double(values.count)
        let tValue = calculateTValue(confidence: confidenceInterval, degreesOfFreedom: Int(n) - 1)
        let margin = tValue * (std / sqrt(n))
        
        return ConfidenceBounds(
            upper: mean + margin,
            lower: mean - margin
        )
    }
}

// MARK: - Helper Methods
private extension StatisticalAnalyzer {
    func calculateTValue(confidence: Double, degreesOfFreedom: Int) -> Double {
        // T-distribution critical values for common confidence levels
        // This is a simplified implementation
        return confidence >= 0.99 ? 2.576 :
               confidence >= 0.95 ? 1.96 :
               confidence >= 0.90 ? 1.645 : 1.28
    }
}
