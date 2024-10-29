import Foundation
import Logging

enum ScheduledAction: Codable {
    case updateSecurity
    case reviewLogs
    case adjustControls
    case patchVulnerabilities
    case rotateCredentials
    case auditPermissions
    case updateBaselines
    case validateIntegrity
    
    struct Schedule {
        let interval: TimeInterval
        let priority: Priority
        let window: ExecutionWindow
        let dependencies: [ScheduledAction]?
        
        enum Priority: Int {
            case critical = 0
            case high = 1
            case normal = 2
            case low = 3
        }
        
        struct ExecutionWindow {
            let startTime: Date
            let duration: TimeInterval
            let recurrence: Recurrence
            
            enum Recurrence {
                case once
                case hourly
                case daily
                case weekly
                case monthly
                case custom(TimeInterval)
            }
        }
    }
    
    var defaultSchedule: Schedule {
        switch self {
        case .updateSecurity:
            return Schedule(
                interval: 24 * 3600,
                priority: .high,
                window: Schedule.ExecutionWindow(
                    startTime: Calendar.current.date(bySettingHour: 2, minute: 0, second: 0, of: Date()) ?? Date(),
                    duration: 3600,
                    recurrence: .daily
                ),
                dependencies: nil
            )
        case .reviewLogs:
            return Schedule(
                interval: 3600,
                priority: .normal,
                window: Schedule.ExecutionWindow(
                    startTime: Date(),
                    duration: 600,
                    recurrence: .hourly
                ),
                dependencies: nil
            )
        // Add similar schedules for other cases
        default:
            return Schedule(
                interval: 86400,
                priority: .normal,
                window: Schedule.ExecutionWindow(
                    startTime: Date(),
                    duration: 1800,
                    recurrence: .daily
                ),
                dependencies: nil
            )
        }
    }
    
    func schedule() -> ActionScheduler {
        return ActionScheduler(action: self, schedule: defaultSchedule)
    }
    
    func execute() async throws -> ActionResult {
        let executor = ScheduledActionExecutor(action: self)
        return try await executor.executeWithSchedule()
    }
    
    func validate() -> ValidationResult {
        let validator = ScheduledActionValidator(action: self)
        return validator.validate()
    }
    
    func generateReport() -> ScheduledActionReport {
        return ScheduledActionReport(
            action: self,
            schedule: defaultSchedule,
            lastExecution: Date(),
            nextExecution: calculateNextExecution(),
            status: .pending
        )
    }
    
    private func calculateNextExecution() -> Date {
        let calculator = NextExecutionCalculator(action: self)
        return calculator.calculate()
    }
}

