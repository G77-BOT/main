struct APIConfig {
    static let shared = APIConfig()
    
    static let baseURL = "https://api.ecosphere.exchange/v1"
    static let apiVersion = "1.0"
    
    struct Endpoints {
        static let auth = "/auth"
        static let transactions = "/transactions"
        static let payments = "/payments"
        static let bookings = "/bookings"
        static let market = "/market"
    }
    
    struct Headers {
        static func defaultHeaders(withAuth: Bool = true) -> [String: String] {
            var headers = [
                "Content-Type": "application/json",
                "X-App-Version": apiVersion,
                "X-Platform": "iOS",
                "X-Device-ID": UIDevice.current.identifierForVendor?.uuidString ?? ""
            ]
            
            if withAuth {
                headers["Authorization"] = "Bearer \(KeychainService.shared.getAccessToken() ?? "")"
            }
            
            return headers
        }
    }
    
    struct TimeoutIntervals {
        static let request: TimeInterval = 30
        static let resource: TimeInterval = 300
    }
}
