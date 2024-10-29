import Foundation
import SwiftData

@Model
final class Order: Identifiable {
    // MARK: - Properties
    
    let id: String
    let buyer: User
    var items: [OrderItem]
    var status: OrderStatus
    let shippingAddress: ShippingAddress
    var paymentInfo: PaymentInfo
    var shippingMethod: ShippingMethod
    let createdAt: Date
    var processedAt: Date?
    var shippedAt: Date?
    var deliveredAt: Date?
    var canceledAt: Date?
    var notes: String?
    var trackingInfo: TrackingInfo?
    var refundInfo: RefundInfo?
    let metadata: [String: String]
    
    // MARK: - Calculated Properties
    
    var subtotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    var tax: Double {
        subtotal * taxRate
    }
    
    var shippingCost: Double {
        shippingMethod.calculateCost(for: self)
    }
    
    var total: Double {
        subtotal + tax + shippingCost
    }
    
    private let taxRate: Double = 0.08 // 8% tax rate
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        buyer: User,
        items: [OrderItem],
        shippingAddress: ShippingAddress,
        paymentInfo: PaymentInfo,
        shippingMethod: ShippingMethod,
        notes: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.buyer = buyer
        self.items = items
        self.status = .pending
        self.shippingAddress = shippingAddress
        self.paymentInfo = paymentInfo
        self.shippingMethod = shippingMethod
        self.notes = notes
        self.createdAt = Date()
        self.metadata = metadata
        
        // Validate order
        validateOrder()
    }
    
    // MARK: - Methods
    
    func process() throws {
        guard status == .pending else {
            throw OrderError.invalidStatus(current: status, expected: .pending)
        }
        
        // Verify stock availability
        try verifyStockAvailability()
        
        // Process payment
        try processPayment()
        
        status = .processing
        processedAt = Date()
    }
    
    func ship(trackingInfo: TrackingInfo) throws {
        guard status == .processing else {
            throw OrderError.invalidStatus(current: status, expected: .processing)
        }
        
        self.trackingInfo = trackingInfo
        status = .shipped
        shippedAt = Date()
    }
    
    func deliver() throws {
        guard status == .shipped else {
            throw OrderError.invalidStatus(current: status, expected: .shipped)
        }
        
        status = .delivered
        deliveredAt = Date()
    }
    
    func cancel(reason: CancellationReason) throws {
        guard status == .pending || status == .processing else {
            throw OrderError.invalidStatus(current: status, expected: [.pending, .processing])
        }
        
        status = .canceled
        canceledAt = Date()
        metadata["cancellation_reason"] = reason.rawValue
    }
    
    func refund(amount: Double, reason: String) throws {
        guard status == .delivered || status == .shipped else {
            throw OrderError.invalidStatus(current: status, expected: [.delivered, .shipped])
        }
        
        let refund = RefundInfo(
            amount: amount,
            reason: reason,
            date: Date(),
            status: .processing
        )
        
        // Process refund
        try processRefund(refund)
        
        self.refundInfo = refund
        status = .refunded
    }
    
    func updatePaymentInfo(_ info: PaymentInfo) throws {
        guard status == .pending else {
            throw OrderError.invalidStatus(current: status, expected: .pending)
        }
        
        self.paymentInfo = info
    }
    
    func updateShippingMethod(_ method: ShippingMethod) throws {
        guard status == .pending else {
            throw OrderError.invalidStatus(current: status, expected: .pending)
        }
        
        self.shippingMethod = method
    }
    
    // MARK: - Private Methods
    
    private func validateOrder() {
        // Implement order validation logic
    }
    
    private func verifyStockAvailability() throws {
        for item in items {
            guard item.product.isAvailable && item.product.quantity >= item.quantity else {
                throw OrderError.insufficientStock(productId: item.product.id)
            }
        }
    }
    
    private func processPayment() throws {
        // Implement payment processing logic
    }
    
    private func processRefund(_ refund: RefundInfo) throws {
        // Implement refund processing logic
    }
}

// MARK: - Supporting Types

struct OrderItem: Codable, Identifiable {
    let id: String
    let product: Item
    let quantity: Int
    let pricePerUnit: Double
    
    var totalPrice: Double {
        Double(quantity) * pricePerUnit
    }
}

enum OrderStatus: String, Codable {
    case pending
    case processing
    case shipped
    case delivered
    case canceled
    case refunded
    case failed
}

struct PaymentInfo: Codable {
    let method: PaymentMethod
    let transactionId: String?
    let status: PaymentStatus
    let lastFour: String?
    let billingAddress: BillingAddress?
}

struct BillingAddress: Codable {
    let fullName: String
    let street: String
    let city: String
    let state: String
    let country: String
    let postalCode: String
}

enum PaymentStatus: String, Codable {
    case pending
    case authorized
    case captured
    case failed
    case refunded
}

struct ShippingMethod: Codable {
    let carrier: String
    let service: String
    let estimatedDays: Int
    let baseRate: Double
    
    func calculateCost(for order: Order) -> Double {
        // Implement shipping cost calculation logic
        return baseRate
    }
}

struct RefundInfo: Codable {
    let amount: Double
    let reason: String
    let date: Date
    var status: RefundStatus
    var transactionId: String?
    var processedDate: Date?
}

enum RefundStatus: String, Codable {
    case processing
    case completed
    case failed
}

enum CancellationReason: String, Codable {
    case customerRequest
    case outOfStock
    case paymentIssue
    case fraudSuspicion
    case other
}

// MARK: - Errors

enum OrderError: LocalizedError {
    case invalidStatus(current: OrderStatus, expected: OrderStatus)
    case invalidStatus(current: OrderStatus, expected: [OrderStatus])
    case insufficientStock(productId: String)
    case paymentFailed(reason: String)
    case invalidAmount
    case processingError
    
    var errorDescription: String? {
        switch self {
        case .invalidStatus(let current, let expected as OrderStatus):
            return "Invalid order status: current status is \(current), expected \(expected)"
        case .invalidStatus(let current, let expected as [OrderStatus]):
            return "Invalid order status: current status is \(current), expected one of \(expected)"
        case .insufficientStock(let productId):
            return "Insufficient stock for product: \(productId)"
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
        case .invalidAmount:
            return "Invalid amount specified"
        case .processingError:
            return "Error processing order"
        default:
            return "Unknown order error"
        }
    }
}

// MARK: - Analytics Extension

extension Order {
    var analyticsData: [String: Any] {
        [
            "order_id": id,
            "buyer_id": buyer.id,
            "status": status.rawValue,
            "total_amount": total,
            "subtotal": subtotal,
            "tax": tax,
            "shipping_cost": shippingCost,
            "item_count": items.count,
            "payment_method": paymentInfo.method.rawValue,
            "shipping_method": shippingMethod.carrier,
            "created_at": createdAt,
            "processed_at": processedAt as Any,
            "shipped_at": shippedAt as Any,
            "delivered_at": deliveredAt as Any,
            "canceled_at": canceledAt as Any,
            "has_refund": refundInfo != nil,
            "items": items.map { [
                "product_id": $0.product.id,
                "quantity": $0.quantity,
                "price": $0.pricePerUnit
            ]}
        ]
    }
}