import Foundation

final class ErrorManager {
    static let shared = ErrorManager()
    
    private let logger = SecurityLogger.shared
    private let analyticsManager = AnalyticsManager.shared
    private let crashReporter = CrashReporter.shared
    private let queue = DispatchQueue(label: "error.manager", qos: .utility)
    
    private var errorHandlers: [ErrorType: [(Error) -> Void]] = [:]
    private var errorCounts: [String: Int] = [:]
    private let errorThreshold = 5
    private let errorTimeWindow: TimeInterval = 300 // 5 minutes
    
    private init() {
        setupDefaultHandlers()
    }
    
    // MARK: - Public Methods
    
    func handle(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Log error
            self.logger.logError(error, file: file, function: function, line: line)
            
            // Track error for analytics
            self.analyticsManager.trackError(error)
            
            // Check if error is critical
            if self.isCriticalError(error) {
                self.handleCriticalError(error)
            }
            
            // Get error type
            let errorType = self.categorizeError(error)
            
            // Track error frequency
            self.trackErrorFrequency(error)
            
            // Execute registered handlers
            self.executeHandlers(for: errorType, with: error)
            
            // Check if error requires user notification
            if self.shouldNotifyUser(error) {
                self.notifyUser(about: error)
            }
        }
    }
    
    func register(handler: @escaping (Error) -> Void, for errorType: ErrorType) {
        queue.async { [weak self] in
            if self?.errorHandlers[errorType] == nil {
                self?.errorHandlers[errorType] = []
            }
            self?.errorHandlers[errorType]?.append(handler)
        }
    }
    
    func unregisterHandlers(for errorType: ErrorType) {
        queue.async { [weak self] in
            self?.errorHandlers[errorType]?.removeAll()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultHandlers() {
        // Network error handler
        register(handler: { [weak self] error in
            if let networkError = error as? NetworkError {
                self?.handleNetworkError(networkError)
            }
        }, for: .network)
        
        // Authentication error handler
        register(handler: { [weak self] error in
            if let authError = error as? AuthenticationError {
                self?.handleAuthenticationError(authError)
            }
        }, for: .authentication)
        
        // Data error handler
        register(handler: { [weak self] error in
            if let dataError = error as? DataError {
                self?.handleDataError(dataError)
            }
        }, for: .data)
        
        // Security error handler
        register(handler: { [weak self] error in
            if let securityError = error as? SecurityError {
                self?.handleSecurityError(securityError)
            }
        }, for: .security)
    }
    
    private func categorizeError(_ error: Error) -> ErrorType {
        switch error {
        case is NetworkError:
            return .network
        case is AuthenticationError:
            return .authentication
        case is DataError:
            return .data
        case is SecurityError:
            return .security
        default:
            return .unknown
        }
    }
    
    private func isCriticalError(_ error: Error) -> Bool {
        if let criticalError = error as? CriticalError {
            return criticalError.isCritical
        }
        return false
    }
    
    private func handleCriticalError(_ error: Error) {
        // Log critical error
        logger.logError(error)
        
        // Report crash
        crashReporter.report(error)
        
        // Notify monitoring service
        analyticsManager.trackEvent(.criticalError(error))
    }
    
    private func executeHandlers(for errorType: ErrorType, with error: Error) {
        errorHandlers[errorType]?.forEach { handler in
            handler(error)
        }
    }
    
    private func trackErrorFrequency(_ error: Error) {
        let errorKey = String(describing: type(of: error))
        
        // Clean up old error counts
        cleanUpErrorCounts()
        
        // Increment error count
        errorCounts[errorKey, default: 0] += 1
        
        // Check if threshold is exceeded
        if errorCounts[errorKey] ?? 0 >= errorThreshold {
            handleFrequentError(error)
        }
    }
    
    private func cleanUpErrorCounts() {
        // Remove error counts older than the time window
        let now = Date()
        errorCounts = errorCounts.filter { _ in
            // In a real implementation, you would store timestamps with the counts
            // and filter based on those timestamps
            true
        }
    }
    
    private func handleFrequentError(_ error: Error) {
        // Log frequent error occurrence
        logger.logWarning("Frequent error detected: \(error)")
        
        // Track analytics
        analyticsManager.trackEvent(.frequentError(error))
        
        // Take appropriate action (e.g., throttling, circuit breaking)
        implementMitigation(for: error)
    }
    
    private func shouldNotifyUser(_ error: Error) -> Bool {
        // Implement logic to determine if error should be shown to user
        if let userFacingError = error as? UserFacingError {
            return userFacingError.shouldNotifyUser
        }
        return false
    }
    
    private func notifyUser(about error: Error) {
        DispatchQueue.main.async {
            // Implement user notification logic
            // This could be showing an alert, toast, or other UI element
        }
    }
    
    private func implementMitigation(for error: Error) {
        // Implement mitigation strategies based on error type
        switch error {
        case is NetworkError:
            NetworkMonitor.shared.throttleRequests()
        case is SecurityError:
            SecurityProvider.shared.increaseSecurity()
        default:
            break
        }
    }
    
    // MARK: - Error Type Handlers
    
    private func handleNetworkError(_ error: NetworkError) {
        switch error {
        case .noConnection:
            // Cache requests for later
            break
        case .timeout:
            // Implement retry logic
            break
        case .serverError:
            // Log and notify monitoring service
            break
        case .securityError:
            // Implement security measures
            break
        }
    }
    
    private func handleAuthenticationError(_ error: AuthenticationError) {
        switch error {
        case .unauthorized:
            // Redirect to login
            break
        case .tokenExpired:
            // Refresh token
            break
        case .invalidCredentials:
            // Show error to user
            break
        }
    }
    
    private func handleDataError(_ error: DataError) {
        switch error {
        case .invalidData:
            // Log and handle corrupt data
            break
        case .persistenceError:
            // Handle database errors
            break
        case .decodingError:
            // Handle parsing errors
            break
        }
    }
    
    private func handleSecurityError(_ error: SecurityError) {
        switch error {
        case .encryption:
            // Handle encryption failures
            break
        case .tampering:
            // Handle security breaches
            break
        case .validation:
            // Handle validation failures
            break
        }
    }
}

// MARK: - Supporting Types

enum ErrorType {
    case network
    case authentication
    case data
    case security
    case unknown
}

protocol CriticalError: Error {
    var isCritical: Bool { get }
}

protocol UserFacingError: Error {
    var shouldNotifyUser: Bool { get }
    var userMessage: String { get }
}

enum NetworkError: Error {
    case noConnection
    case timeout
    case serverError
    case securityError
}

enum AuthenticationError: Error {
    case unauthorized
    case tokenExpired
    case invalidCredentials
}

enum DataError: Error {
    case invalidData
    case persistenceError
    case decodingError
}

enum SecurityError: Error {
    case encryption
    case tampering
    case validation
}
