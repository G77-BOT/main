import Foundation
import CryptoKit

final class BehaviorAnomalyDetector {
    private let analysisEngine = AnalysisEngine.shared
    private let securityProvider = SecurityProvider.shared
    
    // Configuration
    private let detectionThreshold = SecurityConfig.shared.SecuritySettings().anomalyDetectionThreshold
    private let learningRate = 0.1
    private let maxHistorySize = 1000
    
    // State
    private var behaviorHistory: [String: [BehaviorPattern]] = [:]
    private var behaviorProfiles: [String: UserBehaviorProfile] = [:]
    private var detectionRules: [BehaviorRule] = []
    
    init() {
        configureDefaultRules()
    }
    
    // MARK: - Public Interface
    
    func analyzeBehavior(_ behavior: UserBehavior) -> BehaviorAnalysisResult {
        // Update behavior history
        updateBehaviorHistory(behavior)
        
        // Get or create user profile
        let profile = getOrCreateProfile(for: behavior.userId)
        
        // Analyze behavior against profile
        let deviations = detectDeviations(behavior, against: profile)
        
        // Check for rule violations
        let ruleViolations = checkRuleViolations(behavior)
        
        // Calculate anomaly score
        let anomalyScore = calculateAnomalyScore(
            deviations: deviations,
            ruleViolations: ruleViolations
        )
        
        // Update profile with new behavior if not anomalous
        if anomalyScore < detectionThreshold {
            updateProfile(profile, with: behavior)
        }
        
        return BehaviorAnalysisResult(
            userId: behavior.userId,
            timestamp: behavior.timestamp,
            anomalyScore: anomalyScore,
            deviations: deviations,
            ruleViolations: ruleViolations,
            isAnomaly: anomalyScore >= detectionThreshold
        )
    }
    
    func addDetectionRule(_ rule: BehaviorRule) {
        detectionRules.append(rule)
    }
    
    func removeDetectionRule(id: UUID) {
        detectionRules.removeAll { $0.id == id }
    }
    
    // MARK: - Private Implementation
    
    private func configureDefaultRules() {
        // Authentication Rules
        addDetectionRule(BehaviorRule(
            name: "Multiple Failed Logins",
            condition: { behavior in
                if let failedAttempts = behavior.metadata["failedLoginAttempts"] as? Int {
                    return failedAttempts >= 3
                }
                return false
            },
            score: 0.8
        ))
        
        // Time-based Rules
        addDetectionRule(BehaviorRule(
            name: "Unusual Access Time",
            condition: { behavior in
                let hour = Calendar.current.component(.hour, from: behavior.timestamp)
                return hour < 6 || hour > 22 // Outside normal hours
            },
            score: 0.6
        ))
        
        // Location Rules
        addDetectionRule(BehaviorRule(
            name: "Unusual Location",
            condition: { behavior in
                guard let location = behavior.metadata["location"] as? String,
                      let knownLocations = behavior.metadata["knownLocations"] as? [String] else {
                    return false
                }
                return !knownLocations.contains(location)
            },
            score: 0.7
        ))
    }
    
    private func updateBehaviorHistory(_ behavior: UserBehavior) {
        let pattern = BehaviorPattern(
            actions: behavior.actions,
            timestamp: behavior.timestamp,
            metadata: behavior.metadata
        )
        
        if behaviorHistory[behavior.userId] == nil {
            behaviorHistory[behavior.userId] = []
        }
        
        behaviorHistory[behavior.userId]?.append(pattern)
        
        // Trim history if needed
        if let count = behaviorHistory[behavior.userId]?.count,
           count > maxHistorySize {
            behaviorHistory[behavior.userId]?.removeFirst(count - maxHistorySize)
        }
    }
    
    private func getOrCreateProfile(for userId: String) -> UserBehaviorProfile {
        if let existing = behaviorProfiles[userId] {
            return existing
        }
        
        let newProfile = UserBehaviorProfile(userId: userId)
        behaviorProfiles[userId] = newProfile
        return newProfile
    }
    
    private func detectDeviations(_ behavior: UserBehavior, against profile: UserBehaviorProfile) -> [BehaviorDeviation] {
        var deviations: [BehaviorDeviation] = []
        
        // Check action patterns
        let actionDeviation = calculateActionDeviation(
            behavior.actions,
            against: profile.commonActions
        )
        if actionDeviation > detectionThreshold {
            deviations.append(BehaviorDeviation(
                type: .actionPattern,
                score: actionDeviation,
                description: "Unusual action pattern detected"
            ))
        }
        
        // Check timing patterns
        let timingDeviation = calculateTimingDeviation(
            behavior.timestamp,
            against: profile.activityTimes
        )
        if timingDeviation > detectionThreshold {
            deviations.append(BehaviorDeviation(
                type: .timing,
                score: timingDeviation,
                description: "Unusual timing pattern detected"
            ))
        }
        
        // Check metadata patterns
        let metadataDeviations = calculateMetadataDeviations(
            behavior.metadata,
            against: profile.metadataPatterns
        )
        deviations.append(contentsOf: metadataDeviations)
        
        return deviations
    }
    
    private func checkRuleViolations(_ behavior: UserBehavior) -> [RuleViolation] {
        return detectionRules.compactMap { rule in
            if rule.condition(behavior) {
                return RuleViolation(
                    rule: rule,
                    description: "Violated rule: \(rule.name)"
                )
            }
            return nil
        }
    }
    
    private func calculateAnomalyScore(
        deviations: [BehaviorDeviation],
        ruleViolations: [RuleViolation]
    ) -> Double {
        var score = 0.0
        
        // Calculate deviation component
        if !deviations.isEmpty {
            let deviationScore = deviations.reduce(0.0) { $0 + $1.score }
            score += deviationScore / Double(deviations.count) * 0.6 // 60% weight
        }
        
        // Calculate rule violation component
        if !ruleViolations.isEmpty {
            let violationScore = ruleViolations.reduce(0.0) { $0 + $1.rule.score }
            score += violationScore / Double(ruleViolations.count) * 0.4 // 40% weight
        }
        
        return min(max(score, 0), 1)
    }
    
    private func updateProfile(_ profile: UserBehaviorProfile, with behavior: UserBehavior) {
        // Update action frequencies
        behavior.actions.forEach { action in
            profile.commonActions[action, default: 0] += 1
        }
        
        // Update activity times
        let hour = Calendar.current.component(.hour, from: behavior.timestamp)
        profile.activityTimes[hour, default: 0] += 1
        
        // Update metadata patterns
        behavior.metadata.forEach { key, value in
            if profile.metadataPatterns[key] == nil {
                profile.metadataPatterns[key] = []
            }
            profile.metadataPatterns[key]?.append(value)
            
            // Trim metadata history if needed
            if let count = profile.metadataPatterns[key]?.count,
               count > maxHistorySize {
                profile.metadataPatterns[key]?.removeFirst(count - maxHistorySize)
            }
        }
    }
    
    private func calculateActionDeviation(
        _ actions: [String],
        against commonActions: [String: Int]
    ) -> Double {
        guard !commonActions.isEmpty else { return 1.0 }
        
        let totalActions = Double(commonActions.values.reduce(0, +))
        var deviation = 0.0
        
        actions.forEach { action in
            let expectedFrequency = Double(commonActions[action, default: 0]) / totalActions
            deviation += (1.0 - expectedFrequency)
        }
        
        return deviation / Double(actions.count)
    }
    
    private func calculateTimingDeviation(
        _ timestamp: Date,
        against activityTimes: [Int: Int]
    ) -> Double {
        guard !activityTimes.isEmpty else { return 1.0 }
        
        let hour = Calendar.current.component(.hour, from: timestamp)
        let totalActivities = Double(activityTimes.values.reduce(0, +))
        let hourlyFrequency = Double(activityTimes[hour, default: 0]) / totalActivities
        
        return 1.0 - hourlyFrequency
    }
    
    private func calculateMetadataDeviations(
        _ metadata: [String: Any],
        against patterns: [String: [Any]]
    ) -> [BehaviorDeviation] {
        var deviations: [BehaviorDeviation] = []
        
        metadata.forEach { key, value in
            if let pattern = patterns[key] {
                let deviation = calculateValueDeviation(value, against: pattern)
                if deviation > detectionThreshold {
                    deviations.append(BehaviorDeviation(
                        type: .metadata(key),
                        score: deviation,
                        description: "Unusual value for metadata: \(key)"
                    ))
                }
            } else {
                deviations.append(BehaviorDeviation(
                    type: .metadata(key),
                    score: 1.0,
                    description: "New metadata field: \(key)"
                ))
            }
        }
        
        return deviations
    }
    
    private func calculateValueDeviation(_ value: Any, against pattern: [Any]) -> Double {
        // Implement value comparison logic based on type
        // This is a simplified version
        let matches = pattern.contains { compareValues($0, value) }
        return matches ? 0.0 : 1.0
    }
    
    private func compareValues(_ a: Any, _ b: Any) -> Bool {
        // Implement value comparison logic
        return String(describing: a) == String(describing: b)
    }
}

// MARK: - Supporting Types

struct BehaviorPattern {
    let actions: [String]
    let timestamp: Date
    let metadata: [String: Any]
}

class UserBehaviorProfile {
    let userId: String
    var commonActions: [String: Int]
    var activityTimes: [Int: Int]
    var metadataPatterns: [String: [Any]]
    
    init(userId: String) {
        self.userId = userId
        self.commonActions = [:]
        self.activityTimes = [:]
        self.metadataPatterns = [:]
    }
}

struct BehaviorRule {
    let id: UUID
    let name: String
    let condition: (UserBehavior) -> Bool
    let score: Double
    
    init(name: String, condition: @escaping (UserBehavior) -> Bool, score: Double) {
        self.id = UUID()
        self.name = name
        self.condition = condition
        self.score = score
    }
}

struct BehaviorDeviation {
    let type: DeviationType
    let score: Double
    let description: String
}

enum DeviationType {
    case actionPattern
    case timing
    case metadata(String)
}

struct RuleViolation {
    let rule: BehaviorRule
    let description: String
}

struct BehaviorAnalysisResult {
    let userId: String
    let timestamp: Date
    let anomalyScore: Double
    let deviations: [BehaviorDeviation]
    let ruleViolations: [RuleViolation]
    let isAnomaly: Bool
}
