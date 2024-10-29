import Foundation

// MARK: - Base Error Protocol
protocol AppError: LocalizedError {
    var identifier: String { get }
    var severity: ErrorSeverity { get }
    var category: ErrorCategory { get }
    var isRecoverable: Bool { get }
    var recoverySuggestion: String? { get }
    var additionalInfo: [String: Any]? { get }
}

// MARK: - Error Severity
enum ErrorSeverity: Int {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3
    
    var description: String {
        switch self {
        case .low:
            return "Low severity error"
        case .medium:
            return "Medium severity error"
        case .high:
            return "High severity error"
        case .critical:
            return "Critical error"
        }
    }
    
    var requiresImmediate: Bool {
        return self == .critical
    }
}

// MARK: - Error Categories
enum ErrorCategory {
    case network
    case authentication
    case database
    case validation
    case security
    case business
    case system
    case ui
    case unknown
    
    var description: String {
        switch self {
        case .network:
            return "Network Error"
        case .authentication:
            return "Authentication Error"
        case .database:
            return "Database Error"
        case .validation:
            return "Validation Error"
        case .security:
            return "Security Error"
        case .business:
            return "Business Logic Error"
        case .system:
            return "System Error"
        case .ui:
            return "UI Error"
        case .unknown:
            return "Unknown Error"
        }
    }
}

// MARK: - Specific Error Types

// Network Errors
enum NetworkError: AppError {
    case connectionFailed(underlying: Error?)
    case timeout(endpoint: String)
    case invalidResponse(statusCode: Int)
    case noData
    case decodingFailed(underlying: Error)
    case serverError(message: String)
    
    var identifier: String {
        switch self {
        case .connectionFailed:
            return "network.connection.failed"
        case .timeout:
            return "network.timeout"
        case .invalidResponse:
            return "network.response.invalid"
        case .noData:
            return "network.data.missing"
        case .decodingFailed:
            return "network.decoding.failed"
        case .serverError:
            return "network.server.error"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .serverError:
            return .high
        case .connectionFailed, .timeout:
            return .medium
        default:
            return .low
        }
    }
    
    var category: ErrorCategory {
        return .network
    }
    
    var isRecoverable: Bool {
        switch self {
        case .timeout, .connectionFailed:
            return true
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let error):
            return "Failed to connect to the server: \(error?.localizedDescription ?? "Unknown error")"
        case .timeout(let endpoint):
            return "Request timed out for endpoint: \(endpoint)"
        case .invalidResponse(let statusCode):
            return "Received invalid response with status code: \(statusCode)"
        case .noData:
            return "No data received from the server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .connectionFailed, .timeout:
            return "Please check your internet connection and try again"
        case .invalidResponse, .serverError:
            return "Please try again later or contact support if the problem persists"
        case .decodingFailed:
            return "Please update the app to the latest version"
        case .noData:
            return "Please refresh and try again"
        }
    }
    
    var additionalInfo: [String: Any]? {
        switch self {
        case .connectionFailed(let error):
            return ["underlying_error": error as Any]
        case .timeout(let endpoint):
            return ["endpoint": endpoint]
        case .invalidResponse(let statusCode):
            return ["status_code": statusCode]
        case .decodingFailed(let error):
            return ["decoding_error": error]
        case .serverError(let message):
            return ["server_message": message]
        case .noData:
            return nil
        }
    }
}

// Authentication Errors
enum AuthenticationError: AppError {
    case invalidCredentials
    case sessionExpired
    case unauthorized
    case tokenError(reason: String)
    
    var identifier: String {
        switch self {
        case .invalidCredentials:
            return "auth.credentials.invalid"
        case .sessionExpired:
            return "auth.session.expired"
        case .unauthorized:
            return "auth.unauthorized"
        case .tokenError:
            return "auth.token.error"
        }
    }
    
    var severity: ErrorSeverity {
        return .high
    }
    
    var category: ErrorCategory {
        return .authentication
    }
    
    var isRecoverable: Bool {
        switch self {
        case .sessionExpired, .tokenError:
            return true
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password"
        case .sessionExpired:
            return "Your session has expired"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .tokenError(let reason):
            return "Authentication token error: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Please check your credentials and try again"
        case .sessionExpired, .tokenError:
            return "Please log in again"
        case .unauthorized:
            return "Please contact support if you believe this is an error"
        }
    }
    
    var additionalInfo: [String: Any]? {
        switch self {
        case .tokenError(let reason):
            return ["reason": reason]
        default:
            return nil
        }
    }
}

// Validation Errors
enum ValidationError: AppError {
    case invalidInput(field: String, reason: String)
    case missingRequired(field: String)
    case invalidFormat(field: String, expectedFormat: String)
    case businessRule(rule: String, details: String)
    
    var identifier: String {
        switch self {
        case .invalidInput:
            return "validation.input.invalid"
        case .missingRequired:
            return "validation.required.missing"
        case .invalidFormat:
            return "validation.format.invalid"
        case .businessRule:
            return "validation.business.rule"
        }
    }
    
    var severity: ErrorSeverity {
        return .medium
    }
    
    var category: ErrorCategory {
        return .validation
    }
    
    var isRecoverable: Bool {
        return true
    }
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let field, let reason):
            return "Invalid input for \(field): \(reason)"
        case .missingRequired(let field):
            return "Missing required field: \(field)"
        case .invalidFormat(let field, let format):
            return "Invalid format for \(field). Expected format: \(format)"
        case .businessRule(let rule, let details):
            return "Business rule violation - \(rule): \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidInput, .invalidFormat:
            return "Please check the input and try again"
        case .missingRequired:
            return "Please fill in all required fields"
        case .businessRule:
            return "Please ensure all business rules are satisfied"
        }
    }
    
    var additionalInfo: [String: Any]? {
        switch self {
        case .invalidInput(let field, let reason):
            return ["field": field, "reason": reason]
        case .missingRequired(let field):
            return ["field": field]
        case .invalidFormat(let field, let format):
            return ["field": field, "expected_format": format]
        case .businessRule(let rule, let details):
            return ["rule": rule, "details": details]
        }
    }
}

// Database Errors
enum DatabaseError: AppError {
    case connectionFailed
    case queryFailed(query: String, reason: String)
    case recordNotFound(type: String, id: String)
    case duplicateKey(field: String)
    case invalidData(details: String)
    
    var identifier: String {
        switch self {
        case .connectionFailed:
            return "database.connection.failed"
        case .queryFailed:
            return "database.query.failed"
        case .recordNotFound:
            return "database.record.notfound"
        case .duplicateKey:
            return "database.key.duplicate"
        case .invalidData:
            return "database.data.invalid"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .connectionFailed:
            return .critical
        case .queryFailed:
            return .high
        default:
            return .medium
        }
    }
    
    var category: ErrorCategory {
        return .database
    }
    
    var isRecoverable: Bool {
        switch self {
        case .connectionFailed, .queryFailed:
            return true
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to the database"
        case .queryFailed(let query, let reason):
            return "Query failed: \(query), Reason: \(reason)"
        case .recordNotFound(let type, let id):
            return "\(type) with ID \(id) not found"
        case .duplicateKey(let field):
            return "Duplicate value for field: \(field)"
        case .invalidData(let details):
            return "Invalid data: \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .connectionFailed:
            return "Please try again later or contact support"
        case .queryFailed:
            return "Please try again or contact support if the problem persists"
        case .recordNotFound:
            return "Please check the ID and try again"
        case .duplicateKey:
            return "Please use a unique value"
        case .invalidData:
            return "Please check the data format and try again"
        }
    }
    
    var additionalInfo: [String: Any]? {
        switch self {
        case .queryFailed(let query, let reason):
            return ["query": query, "reason": reason]
        case .recordNotFound(let type, let id):
            return ["type": type, "id": id]
        case .duplicateKey(let field):
            return ["field": field]
        case .invalidData(let details):
            return ["details": details]
        default:
            return nil
        }
    }
}

// Security Errors
enum SecurityError: AppError {
    case unauthorized(reason: String)
    case encryptionFailed(details: String)
    case invalidSignature
    case tokenExpired
    case compromisedData
    
    var identifier: String {
        switch self {
        case .unauthorized:
            return "security.unauthorized"
        case .encryptionFailed:
            return "security.encryption.failed"
        case .invalidSignature:
            return "security.signature.invalid"
        case .tokenExpired:
            return "security.token.expired"
        case .compromisedData:
            return "security.data.compromised"
        }
    }
    
    var severity: ErrorSeverity {
        return .critical
    }
    
    var category: ErrorCategory {
        return .security
    }
    
    var isRecoverable: Bool {
        switch self {
        case .tokenExpired:
            return true
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .unauthorized(let reason):
            return "Security violation: \(reason)"
        case .encryptionFailed(let details):
            return "Encryption failed: \(details)"
        case .invalidSignature:
            return "Invalid security signature detected"
        case .tokenExpired:
            return "Security token has expired"
        case .compromisedData:
            return "Data integrity has been compromised"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "Please ensure you have the necessary permissions"
        case .encryptionFailed:
            return "Please try again or contact support"
        case .invalidSignature:
            return "Please verify your security credentials"
        case .tokenExpired:
            return "Please log in again to refresh your security token"
        case .compromisedData:
            return "Please contact security support immediately"
        }
    }
    
    var additionalInfo: [String: Any]? {
        switch self {
        case .unauthorized(let reason):
            return ["reason": reason]
        case .encryptionFailed(let details):
            return ["details": details]
        default:
            return nil
        }
    }
}

// System Errors
enum SystemError: AppError {
    case outOfMemory
    case diskFull
    case resourceUnavailable(resource: String)
    case processTerminated(reason: String)
    
    var identifier: String {
        switch self {
        case .outOfMemory:
            return "system.memory.exhausted"
        case .diskFull:
            return "system.disk.full"
        case .resourceUnavailable:
            return "system.resource.unavailable"
        case .processTerminated:
            return "system.process.terminated"
        }
    }
    
    var severity: ErrorSeverity {
        return .critical
    }
    
    var category: ErrorCategory {
        return .system
    }
    
    var isRecoverable: Bool {
        switch self {
        case .outOfMemory, .diskFull:
            return true
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .outOfMemory:
            return "System is out of memory"
        case .diskFull:
            return "Device storage is full"
        case .resourceUnavailable(let resource):
            return "System resource unavailable: \(resource)"
        case .processTerminated(let reason):
            return "Process terminated: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .outOfMemory:
            return "Please close other applications and try again"
        case .diskFull:
            return "Please free up device storage and try again"
        case .resourceUnavailable:
            return "Please try again later or restart the application"
        case .processTerminated:
            return "Please restart the application"
        }
    }
    
    var additionalInfo: [String: Any]? {
        switch self {
        case .resourceUnavailable(let resource):
            return ["resource": resource]
        case .processTerminated(let reason):
            return ["reason": reason]
        default:
            return nil
        }
    }
}

// Extension to standardize error handling
extension AppError {
    func log() {
        SecurityLogger.shared.logError(self as Error)
    }
    
    func track() {
        AnalyticsManager.shared.trackError(self as Error)
    }
    
    func report() {
        CrashReporter.shared.report(self as Error)
    }
}