import Foundation

enum AnalyticsEvent: Codable {
    case screenView(screenName: String, timestamp: Date, parameters: [String: Any]?)
    case userAction(action: String, timestamp: Date, parameters: [String: Any]?)
    case error(error: Error, timestamp: Date, parameters: [String: Any]?)
    case networkRequest(url: URL, method: String, statusCode: Int, duration: TimeInterval, timestamp: Date)
    case appLifecycle(state: AppState, timestamp: Date)
    case performance(metric: PerformanceMetric, value: Double, timestamp: Date)
    case userLogin(success: Bool, error: Error? = nil)
    case userRegistration(success: Bool, error: Error? = nil)
    case userLogout(success: Bool, error: Error? = nil)
    case transaction(id: String, amount: Double, currency: String, status: TransactionStatus)
    case search(query: String, resultCount: Int, duration: TimeInterval)
    
    // MARK: - Coding Keys
    
    private enum CodingKeys: String, CodingKey {
        case type, data, timestamp
    }
    
    // MARK: - Types
    
    enum AppState: String, Codable {
        case foreground
        case background
        case terminated
        case launch
    }
    
    enum TransactionStatus: String, Codable {
        case initiated
        case processing
        case completed
        case failed
        case canceled
    }
    
    enum PerformanceMetric: String, Codable {
        case memoryUsage
        case cpuUsage
        case frameRate
        case networkLatency
        case appStartTime
        case screenLoadTime
    }
    
    // MARK: - Codable Implementation
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .screenView(let screenName, let timestamp, let parameters):
            try container.encode("screen_view", forKey: .type)
            try container.encode([
                "screen_name": screenName,
                "parameters": parameters ?? [:]
            ], forKey: .data)
            try container.encode(timestamp, forKey: .timestamp)
            
        case .userAction(let action, let timestamp, let parameters):
            try container.encode("user_action", forKey: .type)
            try container.encode([
                "action": action,
                "parameters": parameters ?? [:]
            ], forKey: .data)
            try container.encode(timestamp, forKey: .timestamp)
            
        case .error(let error, let timestamp, let parameters):
            try container.encode("error", forKey: .type)
            try container.encode([
                "error": error.localizedDescription,
                "error_code": (error as NSError).code,
                "parameters": parameters ?? [:]
            ], forKey: .data)
            try container.encode(timestamp, forKey: .timestamp)
            
        case .networkRequest(let url, let method, let statusCode, let duration, let timestamp):
            try container.encode("network_request", forKey: .type)
            try container.encode([
                "url": url.absoluteString,
                "method": method,
                "status_code": statusCode,
                "duration": duration
            ], forKey: .data)
            try container.encode(timestamp, forKey: .timestamp)
            
        case .appLifecycle(let state, let timestamp):
            try container.encode("app_lifecycle", forKey: .type)
            try container.encode([
                "state": state.rawValue
            ], forKey: .data)
            try container.encode(timestamp, forKey: .timestamp)
            
        case .performance(let metric, let value, let timestamp):
            try container.encode("performance", forKey: .type)
            try container.encode([
                "metric": metric.rawValue,
                "value": value
            ], forKey: .data)
            try container.encode(timestamp, forKey: .timestamp)
            
        case .userLogin(let success, let error):
            try container.encode("user_login", forKey: .type)
            try container.encode([
                "success": success,
                "error": error?.localizedDescription as Any
            ], forKey: .data)
            try container.encode(Date(), forKey: .timestamp)
            
        case .userRegistration(let success, let error):
            try container.encode("user_registration", forKey: .type)
            try container.encode([
                "success": success,
                "error": error?.localizedDescription as Any
            ], forKey: .data)
            try container.encode(Date(), forKey: .timestamp)
            
        case .userLogout(let success, let error):
            try container.encode("user_logout", forKey: .type)
            try container.encode([
                "success": success,
                "error": error?.localizedDescription as Any
            ], forKey: .data)
            try container.encode(Date(), forKey: .timestamp)
            
        case .transaction(let id, let amount, let currency, let status):
            try container.encode("transaction", forKey: .type)
            try container.encode([
                "transaction_id": id,
                "amount": amount,
                "currency": currency,
                "status": status.rawValue
            ], forKey: .data)
            try container.encode(Date(), forKey: .timestamp)
            
        case .search(let query, let resultCount, let duration):
            try container.encode("search", forKey: .type)
            try container.encode([
                "query": query,
                "result_count": resultCount,
                "duration": duration
            ], forKey: .data)
            try container.encode(Date(), forKey: .timestamp)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let data = try container.decode([String: Any].self, forKey: .data)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        switch type {
        case "screen_view":
            guard let screenName = data["screen_name"] as? String else {
                throw DecodingError.dataCorruptedError(forKey: .data, in: container, debugDescription: "Invalid screen name")
            }
            let parameters = data["parameters"] as? [String: Any]
            self = .screenView(screenName: screenName, timestamp: timestamp, parameters: parameters)
            
        // Add other cases as needed
        
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown event type")
        }
    }
}

// MARK: - Helpers

extension KeyedDecodingContainer {
    func decode(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any] {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode([String: Any].self)
    }
}

extension KeyedEncodingContainer {
    mutating func encode(_ value: [String: Any], forKey key: K) throws {
        var container = self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        try container.encode(value)
    }
}

struct JSONCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer {
    func decode(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any] {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode()
    }
}

extension KeyedDecodingContainer where K == JSONCodingKeys {
    func decode() throws -> [String: Any] {
        var dict = [String: Any]()
        
        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dict[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dict[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dict[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dict[key.stringValue] = doubleValue
            } else if let nestedDict = try? self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key) {
                dict[key.stringValue] = try nestedDict.decode()
            } else if let nestedArray = try? self.nestedUnkeyedContainer(forKey: key) {
                dict[key.stringValue] = try decode(array: nestedArray)
            }
        }
        return dict
    }
    
    func decode(array: UnkeyedDecodingContainer) throws -> [Any] {
        var array: [Any] = []
        var arrayContainer = array
        
        while !arrayContainer.isAtEnd {
            if let value = try? arrayContainer.decode(Bool.self) {
                array.append(value)
            } else if let value = try? arrayContainer.decode(String.self) {
                array.append(value)
            } else if let value = try? arrayContainer.decode(Int.self) {
                array.append(value)
            } else if let value = try? arrayContainer.decode(Double.self) {
                array.append(value)
            } else if let nestedContainer = try? arrayContainer.nestedContainer(keyedBy: JSONCodingKeys.self) {
                array.append(try nestedContainer.decode())
            } else if let nestedArray = try? arrayContainer.nestedUnkeyedContainer() {
                array.append(try decode(array: nestedArray))
            }
        }
        return array
    }
}

extension KeyedEncodingContainer {
    mutating func encode(_ value: [String: Any]) throws {
        try value.forEach { (key: String, value: Any) in
            guard let codingKey = JSONCodingKeys(stringValue: key) else { return }
            
            switch value {
            case let value as Bool:
                try encode(value, forKey: codingKey)
            case let value as Int:
                try encode(value, forKey: codingKey)
            case let value as String:
                try encode(value, forKey: codingKey)
            case let value as Double:
                try encode(value, forKey: codingKey)
            case let value as [String: Any]:
                var container = self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: codingKey)
                try container.encode(value)
            case let value as [Any]:
                var container = self.nestedUnkeyedContainer(forKey: codingKey)
                try container.encode(array: value)
            default:
                break
            }
        }
    }
}

extension UnkeyedEncodingContainer {
    mutating func encode(array: [Any]) throws {
        try array.forEach { value in
            switch value {
            case let value as Bool:
                try encode(value)
            case let value as Int:
                try encode(value)
            case let value as String:
                try encode(value)
            case let value as Double:
                try encode(value)
            case let value as [String: Any]:
                var container = self.nestedContainer(keyedBy: JSONCodingKeys.self)
                try container.encode(value)
            case let value as [Any]:
                var container = self.nestedUnkeyedContainer()
                try container.encode(array: value)
            default:
                break
            }
        }
    }
}