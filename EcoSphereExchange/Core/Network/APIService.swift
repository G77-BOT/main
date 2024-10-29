import Foundation

final class APIService {
    static let shared = APIService()
    
    private let session: URLSession
    private let securityProvider: SecurityProvider
    private let analyticsManager: AnalyticsManager
    private let errorManager: ErrorManager
    private let queue = DispatchQueue(label: "api.service", qos: .userInitiated)
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = NetworkConfig.requestTimeout
        config.timeoutIntervalForResource = NetworkConfig.resourceTimeout
        config.waitsForConnectivity = true
        config.httpMaximumConnectionsPerHost = 6
        
        // Configure cache
        let cache = URLCache(
            memoryCapacity: NetworkConfig.cacheSizeMemory,
            diskCapacity: NetworkConfig.cacheSizeDisk,
            diskPath: "network_cache"
        )
        config.urlCache = cache
        
        // Configure headers
        config.httpAdditionalHeaders = NetworkConfig.defaultHeaders
        
        session = URLSession(configuration: config)
        securityProvider = SecurityProvider.shared
        analyticsManager = AnalyticsManager.shared
        errorManager = ErrorManager.shared
        
        setupSecurityChecks()
    }
    
    // MARK: - Public Methods
    
    func get<T: Codable>(endpoint: Endpoint) async throws -> T {
        try await request(endpoint: endpoint, method: "GET")
    }
    
    func post<T: Codable>(endpoint: Endpoint, body: Encodable? = nil) async throws -> T {
        try await request(endpoint: endpoint, method: "POST", body: body)
    }
    
    func put<T: Codable>(endpoint: Endpoint, body: Encodable) async throws -> T {
        try await request(endpoint: endpoint, method: "PUT", body: body)
    }
    
    func delete<T: Codable>(endpoint: Endpoint) async throws -> T {
        try await request(endpoint: endpoint, method: "DELETE")
    }
    
    // MARK: - Private Methods
    
    private func request<T: Codable>(endpoint: Endpoint, method: String, body: Encodable? = nil) async throws -> T {
        let startTime = Date()
        let url = try buildURL(for: endpoint)
        var request = try buildRequest(for: url, method: method, endpoint: endpoint)
        
        if let body = body {
            request.httpBody = try encodeBody(body)
        }
        
        do {
            // Track request start
            analyticsManager.trackEvent(.networkRequest(
                url: url,
                method: method,
                headers: request.allHTTPHeaderFields ?? [:],
                body: request.httpBody
            ))
            
            let (data, response) = try await sendRequest(request)
            
            // Track request completion
            let duration = Date().timeIntervalSince(startTime)
            trackRequestCompletion(url: url, method: method, duration: duration)
            
            // Validate response
            try validateResponse(response)
            
            // Decrypt if needed
            let decryptedData = try await decryptResponseIfNeeded(data)
            
            // Decode response
            return try decodeResponse(decryptedData)
            
        } catch {
            handleError(error, endpoint: endpoint)
            throw error
        }
    }
    
    private func buildURL(for endpoint: Endpoint) throws -> URL {
        var components = URLComponents(string: NetworkConfig.baseURL + endpoint.path)
        components?.queryItems = endpoint.queryParameters?.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        return url
    }
    
    private func buildRequest(for url: URL, method: String, endpoint: Endpoint) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = endpoint.cachePolicy
        request.timeoutInterval = endpoint.timeoutInterval
        
        // Add endpoint-specific headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add auth token if required
        if endpoint.requiresAuth {
            try addAuthenticationToken(to: &request)
        }
        
        // Add security headers
        try addSecurityHeaders(to: &request)
        
        return request
    }
    
    private func sendRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        if !NetworkMonitor.shared.isConnected {
            throw NetworkError.noConnection
        }
        
        return try await session.data(for: request)
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(statusCode: 0)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw AuthenticationError.unauthorized
        case 403:
            throw AuthenticationError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500...599:
            throw NetworkError.serverError
        default:
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
        }
    }
    
    private func encodeBody(_ body: Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        return try encoder.encode(body)
    }
    
    private func decodeResponse<T: Codable>(_ data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    private func addAuthenticationToken(to request: inout URLRequest) throws {
        guard let token = try? securityProvider.getAuthToken() else {
            throw AuthenticationError.unauthorized
        }
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    private func addSecurityHeaders(to request: inout URLRequest) throws {
        // Add device identifier
        request.setValue(UIDevice.current.identifierForVendor?.uuidString, forHTTPHeaderField: "X-Device-ID")
        
        // Add request timestamp
        let timestamp = String(Int(Date().timeIntervalSince1970))
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        
        // Add request signature
        let signature = try securityProvider.signRequest(
            method: request.httpMethod ?? "",
            path: request.url?.path ?? "",
            timestamp: timestamp
        )
        request.setValue(signature, forHTTPHeaderField: "X-Signature")
    }
    
    private func decryptResponseIfNeeded(_ data: Data) async throws -> Data {
        guard securityProvider.shouldDecryptResponse else {
            return data
        }
        
        return try await securityProvider.decryptResponse(data)
    }
    
    private func setupSecurityChecks() {
        // Certificate pinning
        if NetworkConfig.certificatePinningEnabled {
            securityProvider.setupCertificatePinning(with: NetworkConfig.pinnedCertificates)
        }
        
        // SSL/TLS configuration
        securityProvider.configureSecureConnection(
            allowedProtocols: NetworkConfig.allowedSSLProtocols
        )
    }
    
    private func trackRequestCompletion(url: URL, method: String, duration: TimeInterval) {
        analyticsManager.trackEvent(.networkPerformance(
            url: url,
            method: method,
            duration: duration
        ))
        
        if duration > NetworkConfig.performanceThresholds.slowRequestThreshold {
            SecurityLogger.shared.logWarning("Slow network request: \(method) \(url) (\(duration)s)")
        }
    }
    
    private func handleError(_ error: Error, endpoint: Endpoint) {
        // Log error
        errorManager.handle(error)
        
        // Track error
        analyticsManager.trackEvent(.networkError(
            url: endpoint.path,
            error: error
        ))
        
        // Handle specific error cases
        if let networkError = error as? NetworkError {
            switch networkError {
            case .noConnection:
                // Cache request for later retry
                break
            case .serverError:
                // Notify monitoring service
                break
            default:
                break
            }
        }
    }
}

// MARK: - Supporting Types

enum NetworkError: LocalizedError {
    case invalidURL
    case noConnection
    case timeout
    case invalidResponse(statusCode: Int)
    case serverError
    case notFound
    case decodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .invalidResponse(let statusCode):
            return "Invalid response (status: \(statusCode))"
        case .serverError:
            return "Server error occurred"
        case .notFound:
            return "Resource not found"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

extension NetworkError: AppError {
    var identifier: String {
        switch self {
        case .invalidURL:
            return "network.url.invalid"
        case .noConnection:
            return "network.connection.none"
        case .timeout:
            return "network.timeout"
        case .invalidResponse:
            return "network.response.invalid"
        case .serverError:
            return "network.server.error"
        case .notFound:
            return "network.notfound"
        case .decodingFailed:
            return "network.decoding.failed"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .serverError:
            return .high
        case .noConnection, .timeout:
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
        case .noConnection, .timeout, .serverError:
            return true
        default:
            return false
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Please check your internet connection and try again"
        case .timeout:
            return "Please try again"
        case .serverError:
            return "Please try again later"
        default:
            return nil
        }
    }
    
    var additionalInfo: [String: Any]? {
        switch self {
        case .invalidResponse(let statusCode):
            return ["statusCode": statusCode]
        case .decodingFailed(let error):
            return ["underlyingError": error]
        default:
            return nil
        }
    }
}
