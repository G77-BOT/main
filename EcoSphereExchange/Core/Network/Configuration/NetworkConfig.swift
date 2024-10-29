import Foundation

struct NetworkConfig {
    // Base URLs for different environments
    static let baseURL: String = {
        #if DEBUG
        return "https://api-dev.ecosphereexchange.com/v1"
        #elseif STAGING
        return "https://api-staging.ecosphereexchange.com/v1"
        #else
        return "https://api.ecosphereexchange.com/v1"
        #endif
    }()
    
    // API Versions
    static let apiVersion: String = "v1"
    
    // Timeouts
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 300
    
    // Retry Configuration
    static let maxRetryAttempts: Int = 3
    static let retryStatusCodes: Set<Int> = Set([408, 500, 502, 503, 504])
    static let retryDelay: TimeInterval = 1.0
    static let retryBackoffMultiplier: Double = 2.0
    
    // Cache Configuration
    static let cachePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly
    static let cacheSizeMemory: Int = 10 * 1024 * 1024 // 10MB
    static let cacheSizeDisk: Int = 50 * 1024 * 1024   // 50MB
    
    // Security
    static let certificatePinningEnabled = true
    static let allowedSSLProtocols: [String] = ["TLSv1.2", "TLSv1.3"]
    static let pinnedCertificates: [String] = [
        "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
        "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
    ]
    
    // Rate Limiting
    static let maxRequestsPerSecond = 10
    static let rateLimitBucketSize = 100
    
    // Compression
    static let compressionEnabled = true
    static let minimumSizeForCompression = 1024 // 1KB
    
    // Headers
    static let defaultHeaders: [String: String] = [
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Accept-Encoding": "gzip, deflate",
        "User-Agent": userAgent
    ]
    
    static let userAgent: String = {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        return "EcoSphereExchange/\(appVersion) (\(deviceModel); iOS \(systemVersion)) Build/\(buildNumber)"
    }()
    
    // Endpoints
    enum Endpoint {
        case login
        case register
        case profile
        case transactions
        case markets
        case analytics
        
        var path: String {
            switch self {
            case .login:
                return "/auth/login"
            case .register:
                return "/auth/register"
            case .profile:
                return "/user/profile"
            case .transactions:
                return "/transactions"
            case .markets:
                return "/markets"
            case .analytics:
                return "/analytics"
            }
        }
        
        var requiresAuth: Bool {
            switch self {
            case .login, .register:
                return false
            default:
                return true
            }
        }
        
        var cachePolicy: URLRequest.CachePolicy {
            switch self {
            case .markets:
                return .returnCacheDataElseLoad
            default:
                return .useProtocolCachePolicy
            }
        }
        
        var timeoutInterval: TimeInterval {
            switch self {
            case .transactions:
                return 60 // Longer timeout for transactions
            default:
                return NetworkConfig.requestTimeout
            }
        }
    }
    
    // Error Handling
    enum NetworkErrorCode: Int {
        case badRequest = 400
        case unauthorized = 401
        case forbidden = 403
        case notFound = 404
        case timeout = 408
        case conflict = 409
        case tooManyRequests = 429
        case serverError = 500
        case serviceUnavailable = 503
        
        var isRetryable: Bool {
            switch self {
            case .timeout, .serverError, .serviceUnavailable:
                return true
            default:
                return false
            }
        }
        
        var defaultMessage: String {
            switch self {
            case .badRequest:
                return "Invalid request"
            case .unauthorized:
                return "Please log in to continue"
            case .forbidden:
                return "You don't have permission to access this resource"
            case .notFound:
                return "Resource not found"
            case .timeout:
                return "Request timed out"
            case .conflict:
                return "Resource conflict"
            case .tooManyRequests:
                return "Too many requests. Please try again later"
            case .serverError:
                return "Server error occurred"
            case .serviceUnavailable:
                return "Service temporarily unavailable"
            }
        }
    }
    
    // Monitoring
    static let performanceThresholds = PerformanceThresholds(
        requestTimeout: 10.0,
        slowRequestThreshold: 3.0,
        networkErrorThreshold: 0.1,
        minRequestsForErrorRate: 100
    )
}

struct PerformanceThresholds {
    let requestTimeout: TimeInterval
    let slowRequestThreshold: TimeInterval
    let networkErrorThreshold: Double
    let minRequestsForErrorRate: Int
}

// Extensions
extension URLSession {
    static var configured: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = NetworkConfig.requestTimeout
        configuration.timeoutIntervalForResource = NetworkConfig.resourceTimeout
        configuration.waitsForConnectivity = true
        configuration.httpMaximumConnectionsPerHost = 6
        
        // Configure cache
        let cache = URLCache(
            memoryCapacity: NetworkConfig.cacheSizeMemory,
            diskCapacity: NetworkConfig.cacheSizeDisk,
            diskPath: "network_cache"
        )
        configuration.urlCache = cache
        
        // Configure headers
        configuration.httpAdditionalHeaders = NetworkConfig.defaultHeaders
        
        return URLSession(configuration: configuration)
    }
}