import Foundation

enum SecurityError: LocalizedError {
    case accountLocked
    case invalidCredentials
    case sessionExpired
    case unauthorized
    case biometricNotAvailable
    case biometricAuthenticationFailed(Error)
    case encryptionError(String)
    case networkError(String)
    case serverError(String)
    case invalidInput(String)
    case systemError(String)
    case resourceNotFound(String)
    case certificateValidationFailed
    case insecureConnection
    case maxAttemptsExceeded
    case tokenExpired
    case invalidToken
    case rateLimitExceeded
    case internalError(String)
    
    var errorDescription: String? {
        switch self {
        case .accountLocked:
            return "Account has been locked due to too many failed attempts"
        case .invalidCredentials:
            return "Invalid username or password"
        case .sessionExpired:
            return "Your session has expired. Please log in again"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricAuthenticationFailed(let error):
            return "Biometric authentication failed: \(error.localizedDescription)"
        case .encryptionError(let message):
            return "Encryption error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .systemError(let message):
            return "System error: \(message)"
        case .resourceNotFound(let resource):
            return "Resource not found: \(resource)"
        case .certificateValidationFailed:
            return "SSL/TLS certificate validation failed"
        case .insecureConnection:
            return "Insecure connection detected"
        case .maxAttemptsExceeded:
            return "Maximum number of attempts exceeded"
        case .tokenExpired:
            return "Authentication token has expired"
        case .invalidToken:
            return "Invalid authentication token"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later"
        case .internalError(let message):
            return "Internal error: \(message)"
        }
    }
}