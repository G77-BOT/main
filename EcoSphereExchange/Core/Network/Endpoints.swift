import Foundation

enum Endpoint {
    // Authentication
    case login
    case register
    case logout
    case refreshToken
    case validateToken
    
    // User Management
    case userProfile
    case updateProfile
    case changePassword
    case deleteAccount
    
    // Wallet Operations
    case walletBalance
    case transactions
    case transfer
    case exchangeRates
    
    // Market
    case markets
    case marketDetail(id: String)
    case marketOrders
    case placeOrder
    case cancelOrder(id: String)
    
    // Analytics
    case analytics
    case metrics
    case performance
    
    // Content
    case news
    case notifications
    case search
    
    var path: String {
        switch self {
        // Authentication
        case .login:
            return "/auth/login"
        case .register:
            return "/auth/register"
        case .logout:
            return "/auth/logout"
        case .refreshToken:
            return "/auth/refresh"
        case .validateToken:
            return "/auth/validate"
            
        // User Management
        case .userProfile:
            return "/user/profile"
        case .updateProfile:
            return "/user/profile/update"
        case .changePassword:
            return "/user/password/change"
        case .deleteAccount:
            return "/user/delete"
            
        // Wallet Operations
        case .walletBalance:
            return "/wallet/balance"
        case .transactions:
            return "/wallet/transactions"
        case .transfer:
            return "/wallet/transfer"
        case .exchangeRates:
            return "/wallet/exchange-rates"
            
        // Market
        case .markets:
            return "/markets"
        case .marketDetail(let id):
            return "/markets/\(id)"
        case .marketOrders:
            return "/markets/orders"
        case .placeOrder:
            return "/markets/orders/place"
        case .cancelOrder(let id):
            return "/markets/orders/\(id)/cancel"
            
        // Analytics
        case .analytics:
            return "/analytics"
        case .metrics:
            return "/analytics/metrics"
        case .performance:
            return "/analytics/performance"
            
        // Content
        case .news:
            return "/content/news"
        case .notifications:
            return "/content/notifications"
        case .search:
            return "/content/search"
        }
    }
    
    var method: String {
        switch self {
        case .login, .register, .logout, .transfer, .placeOrder:
            return "POST"
        case .updateProfile, .changePassword:
            return "PUT"
        case .deleteAccount, .cancelOrder:
            return "DELETE"
        default:
            return "GET"
        }
    }
    
    var requiresAuth: Bool {
        switch self {
        case .login, .register, .refreshToken:
            return false
        default:
            return true
        }
    }
    
    var headers: [String: String]? {
        var headers: [String: String] = [:]
        
        // Add common headers
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        // Add custom headers based on endpoint
        switch self {
        case .placeOrder, .transfer:
            headers["Idempotency-Key"] = UUID().uuidString
        default:
            break
        }
        
        return headers
    }
    
    var queryParameters: [String: String]? {
        switch self {
        case .markets:
            return [
                "limit": "50",
                "sort": "volume",
                "order": "desc"
            ]
        case .transactions:
            return [
                "limit": "20",
                "offset": "0"
            ]
        default:
            return nil
        }
    }
    
    var cachePolicy: URLRequest.CachePolicy {
        switch self {
        case .markets, .exchangeRates, .news:
            return .returnCacheDataElseLoad
        default:
            return .useProtocolCachePolicy
        }
    }
    
    var timeoutInterval: TimeInterval {
        switch self {
        case .placeOrder, .transfer:
            return 60 // Longer timeout for critical operations
        default:
            return NetworkConfig.requestTimeout
        }
    }
}

// Request Bodies
extension Endpoint {
    struct LoginRequest: Codable {
        let username: String
        let password: String
        let deviceInfo: DeviceInfo
    }
    
    struct RegisterRequest: Codable {
        let username: String
        let email: String
        let password: String
        let phoneNumber: String
        let address: String
    }
    
    struct TransferRequest: Codable {
        let recipient: String
        let amount: Double
        let currency: String
        let notes: String?
    }
    
    struct OrderRequest: Codable {
        let marketId: String
        let type: OrderType
        let side: OrderSide
        let amount: Double
        let price: Double?
    }
    
    enum OrderType: String, Codable {
        case market
        case limit
    }
    
    enum OrderSide: String, Codable {
        case buy
        case sell
    }
}

// Response Types
extension Endpoint {
    struct AuthResponse: Codable {
        let token: String
        let refreshToken: String
        let expiresIn: Int
        let user: User
    }
    
    struct User: Codable {
        let id: String
        let username: String
        let email: String
        let phoneNumber: String
        let address: String
        let createdAt: Date
        let lastLoginAt: Date?
    }
    
    struct WalletResponse: Codable {
        let balance: Double
        let currency: String
        let lastUpdated: Date
    }
    
    struct TransactionResponse: Codable {
        let id: String
        let type: TransactionType
        let amount: Double
        let currency: String
        let status: TransactionStatus
        let timestamp: Date
    }
    
    enum TransactionType: String, Codable {
        case deposit
        case withdrawal
        case transfer
        case exchange
    }
    
    enum TransactionStatus: String, Codable {
        case pending
        case completed
        case failed
        case cancelled
    }
}

// Device Information
struct DeviceInfo: Codable {
    let deviceId: String
    let platform: String
    let model: String
    let osVersion: String
    let appVersion: String
    
    static var current: DeviceInfo {
        DeviceInfo(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            platform: "iOS",
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        )
    }
}
