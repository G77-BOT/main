import Foundation
import SecurityProvider

final class UserBehaviorAnalyzer {
    static let shared = UserBehaviorAnalyzer()
    private let analysisQueue = DispatchQueue(label: "com.ecosphere.security.behavior", qos: .userInitiated)
    private var behaviorPatterns: [String: BehaviorPattern] = [:]
    
    struct BehaviorPattern: Codable {
        let userId: String
        let patterns: [Pattern]
        let riskScore: Double
        let lastUpdated: Date
        let confidence: Double
        
        struct Pattern: Codable {
            let type: PatternType
            let frequency: Double
            let timeWindow: TimeInterval
            let locations: [Location]
            let devices: [Device]
            
            enum PatternType: String, Codable {
                case authentication
                case transaction
                case navigation
                case dataAccess
                case apiUsage
                case resourceConsumption
            }
        }
    }
    
    func analyzePatterns() async -> BehaviorAnalysis {
        let currentPatterns = await collectCurrentPatterns()
        let historicalPatterns = await loadHistoricalPatterns()
        let analysis = await performAnalysis(current: currentPatterns, historical: historicalPatterns)
        
        await updateBehaviorBaselines(with: analysis)
        return analysis
    }
    
    func detectAnomalies(for userId: String) async -> [BehaviorAnomaly] {
        guard let userPattern = await getUserPattern(userId) else { return [] }
        let detector = BehaviorAnomalyDetector(pattern: userPattern)
        return await detector.detectAnomalies()
    }
    
    func calculateRiskScore(for userId: String) async -> RiskScore {
        let patterns = await getUserPattern(userId)
        let calculator = RiskScoreCalculator(patterns: patterns)
        return calculator.calculate()
    }
    
    private func collectCurrentPatterns() async -> [BehaviorPattern] {
        let collector = PatternCollector()
        return await collector.collect()
    }
    
    private func loadHistoricalPatterns() async -> [BehaviorPattern] {
        return await analysisQueue.sync {
            Array(behaviorPatterns.values)
        }
    }
    
    private func performAnalysis(current: [BehaviorPattern], historical: [BehaviorPattern]) async -> BehaviorAnalysis {
        let analyzer = BehaviorAnalyzer(current: current, historical: historical)
        return await analyzer.analyze()
    }
    
    private func updateBehaviorBaselines(with analysis: BehaviorAnalysis) async {
        let baselineUpdater = BehaviorBaselineUpdater(analysis: analysis)
        await baselineUpdater.update()
    }
    
    private func getUserPattern(_ userId: String) async -> BehaviorPattern? {
        return await analysisQueue.sync {
            behaviorPatterns[userId]
        }
    }
    
    func generateBehaviorReport(for userId: String) async -> BehaviorReport {
        let patterns = await getUserPattern(userId)
        let anomalies = await detectAnomalies(for: userId)
        let riskScore = await calculateRiskScore(for: userId)
        
        return BehaviorReport(
            userId: userId,
            patterns: patterns,
            anomalies: anomalies,
            riskScore: riskScore,
            timestamp: Date()
        )
    }
}