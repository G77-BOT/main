import Foundation
import Logging

struct ResponseResult: Codable {
    let success: Bool
    let executionTime: TimeInterval
    let actionResults: [ActionResult]
    let metrics: ResponseMetrics
    let status: ExecutionStatus
    
    struct ActionResult: Codable {
        let action: SecurityAction
        let status: ActionStatus
        let executionTime: TimeInterval
        let resources: ResourceUsage
        
        enum ActionStatus: Codable {
            case succeeded
            case failed(Error)
            case partial(completionPercentage: Double)
            case timeout
            case cancelled
        }
    }
    
    struct ResponseMetrics: Codable {
        let performance: PerformanceMetrics
        let security: SecurityMetrics
        let resource: ResourceMetrics
        let effectiveness: Double
        
        struct PerformanceMetrics: Codable {
            let responseTime: TimeInterval
            let throughput: Double
            let latency: TimeInterval
            let concurrency: Int
        }
        
        struct SecurityMetrics: Codable {
            let threatContainment: Double
            let vulnerabilityCoverage: Double
            let securityScore: Int
            let riskReduction: Double
        }
        
        struct ResourceMetrics: Codable {
            let cpuUsage: Double
            let memoryUsage: Double
            let networkUsage: Double
            let storageUsage: Double
        }
    }
    
    enum ExecutionStatus: String, Codable {
        case completed
        case failed
        case partial
        case inProgress
        case cancelled
        case timeout
    }
    
    func analyze() -> ResultAnalysis {
        let analyzer = ResultAnalyzer(result: self)
        return analyzer.analyze()
    }
    
    func generateReport() -> ResponseReport {
        return ResponseReport(
            result: self,
            analysis: analyze(),
            recommendations: generateRecommendations(),
            timestamp: Date()
        )
    }
    
    func validateEffectiveness() -> ValidationResult {
        let validator = EffectivenessValidator(result: self)
        return validator.validate()
    }
    
    private func generateRecommendations() -> [ResultRecommendation] {
        let recommendationEngine = RecommendationEngine(result: self)
        return recommendationEngine.generate()
    }
}
