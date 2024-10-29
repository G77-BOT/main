import SwiftUI
import LocalAuthentication
import CryptoKit

class UserSession: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var user: User?
    
    private let secureStorage = SecureStorage.shared
    private let analyticsManager = AnalyticsManager.shared
    
    // MARK: - Authentication
    
    func login(username: String, password: String) async {
        do {
            isLoading = true
            error = nil
            
            // Hash password before sending
            let hashedPassword = hashPassword(password)
            
            // Attempt to authenticate with API
            let credentials = LoginCredentials(username: username, password: hashedPassword)
            let response: AuthResponse = try await APIService.shared.post(endpoint: .login, body: credentials)
            
            // Store auth token securely
            try await secureStorage.store(key: "authToken", value: response.token)
            
            // Store user data
            self.user = response.user
            self.isLoggedIn = true
            
            // Track successful login
            analyticsManager.trackEvent(.userLogin(success: true))
            
        } catch {
            self.error = error.localizedDescription
            analyticsManager.trackEvent(.userLogin(success: false, error: error))
            SecurityLogger.shared.logError(error)
        }
        
        isLoading = false
    }
    
    func authenticateWithBiometrics() async {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            self.error = error?.localizedDescription ?? "Biometric authentication not available"
            return
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access your account"
            )
            
            if success {
                // Attempt to restore session from stored credentials
                try await restoreSession()
            }
        } catch {
            self.error = error.localizedDescription
            SecurityLogger.shared.logError(error)
        }
    }
    
    func signUp(username: String, password: String, email: String, phoneNumber: String, address: String) async {
        do {
            isLoading = true
            error = nil
            
            // Validate input
            guard validateSignUpInput(username: username, password: password, email: email) else {
                throw ValidationError.invalidInput
            }
            
            // Hash password
            let hashedPassword = hashPassword(password)
            
            // Create registration request
            let registrationData = RegistrationData(
                username: username,
                password: hashedPassword,
                email: email,
                phoneNumber: phoneNumber,
                address: address
            )
            
            // Submit registration
            let response: AuthResponse = try await APIService.shared.post(endpoint: .register, body: registrationData)
            
            // Store auth token
            try await secureStorage.store(key: "authToken", value: response.token)
            
            // Update session state
            self.user = response.user
            self.isLoggedIn = true
            
            // Track successful registration
            analyticsManager.trackEvent(.userRegistration(success: true))
            
        } catch {
            self.error = error.localizedDescription
            analyticsManager.trackEvent(.userRegistration(success: false, error: error))
            SecurityLogger.shared.logError(error)
        }
        
        isLoading = false
    }
    
    func logout() async {
        do {
            isLoading = true
            
            // Notify backend of logout
            try await APIService.shared.post(endpoint: .logout, body: EmptyBody())
            
            // Clear stored data
            try await clearUserData()
            
            // Reset session state
            resetSessionState()
            
            analyticsManager.trackEvent(.userLogout(success: true))
            
        } catch {
            self.error = error.localizedDescription
            analyticsManager.trackEvent(.userLogout(success: false, error: error))
            SecurityLogger.shared.logError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func restoreSession() async throws {
        guard let token = try? await secureStorage.retrieve(key: "authToken") else {
            throw SessionError.noStoredCredentials
        }
        
        let response: AuthResponse = try await APIService.shared.get(endpoint: .validateToken)
        self.user = response.user
        self.isLoggedIn = true
    }
    
    private func clearUserData() async throws {
        // Clear secure storage
        try await secureStorage.clearAll()
        
        // Clear any cached data
        await CacheManager.shared.clearAll()
    }
    
    private func resetSessionState() {
        self.user = nil
        self.isLoggedIn = false
        self.error = nil
    }
    
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func validateSignUpInput(username: String, password: String, email: String) -> Bool {
        // Username validation
        guard username.count >= 3 && username.count <= 30 else { return false }
        
        // Password validation (at least 8 chars, 1 uppercase, 1 number, 1 special char)
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$&*])(?=.*[a-z]).{8,}$"
        guard password.range(of: passwordRegex, options: .regularExpression) != nil else { return false }
        
        // Email validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard email.range(of: emailRegex, options: .regularExpression) != nil else { return false }
        
        return true
    }
}

// MARK: - Supporting Types

struct LoginCredentials: Codable {
    let username: String
    let password: String
}

struct RegistrationData: Codable {
    let username: String
    let password: String
    let email: String
    let phoneNumber: String
    let address: String
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let phoneNumber: String
    let address: String
    let createdAt: Date
    let lastLoginAt: Date?
}

struct EmptyBody: Codable {}

enum ValidationError: LocalizedError {
    case invalidInput
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input provided. Please check all fields and try again."
        }
    }
}

enum SessionError: LocalizedError {
    case noStoredCredentials
    
    var errorDescription: String? {
        switch self {
        case .noStoredCredentials:
            return "No stored credentials found. Please log in again."
        }
    }
}
