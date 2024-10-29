import Foundation
import SwiftData

@Model
final class Transaction: Identifiable {
    // MARK: - Properties
    
    let id: String
    let buyer: User
    let seller: User
    let item: Item
    let amount: Double
    let currency: String
    var status: TransactionStatus
    let paymentMethod: PaymentMethod
    let shippingAddress: ShippingAddress
    var trackingInfo: TrackingInfo?
    let createdAt: Date
    var completedAt: Date?
    var canceledAt: Date?
    let paymentId: String?
    var refundId: String?
    var disputeId: String?
    var notes: String?
    let fees: TransactionFees
    var rating: TransactionRating?
    var metadata: [String: String]
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        buyer: User,
        seller: User,
        item: Item,
        amount: Double,
        currency: String,
        paymentMethod: PaymentMethod,
        shippingAddress: ShippingAddress,
        paymentId: String? = nil,
        notes: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.buyer = buyer
        self.seller = seller
        self.item = item
        self.amount = amount
        self.currency = currency
        self.status = .pending
        self.paymentMethod = paymentMethod
        self.shippingAddress = shippingAddress
        self.createdAt = Date()
        self.paymentId = paymentId
        self.notes = notes
        self.fees = TransactionFees(
            platformFee: amount * 0.05,  // 5% platform fee
            paymentProcessingFee: amount * 0.03,  // 3% payment processing fee
            shippingFee: 0.0  // To be calculated based on shipping method
        )
        self.metadata = metadata
    }
    
    // MARK: - Methods
    
    func process() throws {
        guard status == .pending else {
            throw TransactionError.invalidStatus(current: status, expected: .pending)
        }
        
        status = .processing
    }
    
    func complete() throws {
        guard status == .processing else {
            throw TransactionError.invalidStatus(current: status, expected: .processing)
        }
        
        status = .completed
        completedAt = Date()
        
        // Update item quantity
        item.updateQuantity(item.quantity - 1)
        
        // Update buyer and seller stats
        buyer.recordPurchase(self)
        seller.stats.successfulTransactions += 1
        seller.stats.totalTransactions += 1
    }
    
    func cancel(reason: CancellationReason) throws {
        guard status == .pending || status == .processing else {
            throw TransactionError.invalidStatus(current: status, expected: [.pending, .processing])
        }
        
        status = .canceled
        canceledAt = Date()
        metadata["cancellation_reason"] = reason.rawValue
        
        // Update seller stats
        seller.stats.canceledTransactions += 1
        seller.stats.totalTransactions += 1
    }
    
    func addTracking(_ info: TrackingInfo) throws {
        guard status == .processing else {
            throw TransactionError.invalidStatus(current: status, expected: .processing)
        }
        
        self.trackingInfo = info
    }
    
    func initiateDispute(reason: DisputeReason) throws {
        guard status == .completed else {
            throw TransactionError.invalidStatus(current: status, expected: .completed)
        }
        
        status = .disputed
        disputeId = UUID().uuidString
        metadata["dispute_reason"] = reason.rawValue
        metadata["dispute_date"] = ISO8601DateFormatter().string(from: Date())
    }
    
    func resolveDispute(resolution: DisputeResolution) throws {
        guard status == .disputed else {
            throw TransactionError.invalidStatus(current: status, expected: .disputed)
        }
        
        switch resolution {
        case .buyerRefunded:
            status = .refunded
            refundId = UUID().uuidString
        case .sellerFavored:
            status = .completed
        }
        
        metadata["dispute_resolution"] = resolution.rawValue
        metadata["resolution_date"] = ISO8601DateFormatter().string(from: Date())
    }
    
    func rate(_ rating: TransactionRating) throws {
        guard status == .completed else {
            throw TransactionError.invalidStatus(current: status, expected: .completed)
        }
        
        self.rating = rating
    }
    
    // MARK: - Computed Properties
    
    var totalAmount: Double {
        return amount + fees.total
    }
    
    var isDisputable: Bool {
        guard status == .completed else { return false }
        guard let completionDate = completedAt else { return false }
        
        // Allow disputes within 30 days of completion
        return Date().timeIntervalSince(completionDate) <= 30 * 24 * 60 * 60
    }
    
    var isRefundable: Bool {
        guard status == .completed else { return false }
        guard let completionDate = completedAt else { return false }
        
        // Allow refunds within 14 days of completion
        return Date().timeIntervalSince(completionDate) <= 14 * 24 * 60 * 60
    }
}

// MARK: - Supporting Types

enum TransactionStatus: String, Codable {
    case pending
    case processing
    case completed
    case canceled
    case refunded
    case disputed
    case failed
}

enum PaymentMethod: String, Codable {
    case creditCard
    case debit
    case paypal
    case bankTransfer
    case wallet
}

struct ShippingAddress: Codable {
    let fullName: String
    let street: String
    let city: String
    let state: String
    let country: String
    let postalCode: String
    let phone: String?
}

struct TrackingInfo: Codable {
    let carrier: String
    let trackingNumber: String
    let estimatedDelivery: Date?
    var updates: [TrackingUpdate]
}

struct TrackingUpdate: Codable {
    let status: String
    let location: String
    let timestamp: Date
    let details: String?
}

struct TransactionFees: Codable {
    let platformFee: Double
    let paymentProcessingFee: Double
    let shippingFee: Double
    
    var total: Double {
        return platformFee + paymentProcessingFee + shippingFee
    }
}

struct TransactionRating: Codable {
    let rating: Int  // 1-5
    let comment: String?
    let aspects: [RatingAspect: Int]
    let timestamp: Date
}

enum RatingAspect: String, Codable {
    case itemAccuracy
    case communication
    case shippingSpeed
    case itemCondition
}

enum CancellationReason: String, Codable {
    case buyerRequested
    case outOfStock
    case paymentFailed
    case shippingIssue
    case other
}

enum DisputeReason: String, Codable {
    case itemNotReceived
    case itemNotAsDescribed
    case damaged
    case wrongItem
    case fraudulent
}

enum DisputeResolution: String, Codable {
    case buyerRefunded
    case sellerFavored
}

// MARK: - Error Types

enum TransactionError: LocalizedError {
    case invalidStatus(current: TransactionStatus, expected: TransactionStatus)
    case invalidStatus(current: TransactionStatus, expected: [TransactionStatus])
    case insufficientFunds
    case itemUnavailable
    case paymentFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidStatus(let current, let expected as TransactionStatus):
            return "Invalid transaction status: current status is \(current), expected \(expected)"
        case .invalidStatus(let current, let expected as [TransactionStatus]):
            return "Invalid transaction status: current status is \(current), expected one of \(expected)"
        case .insufficientFunds:
            return "Insufficient funds to complete transaction"
        case .itemUnavailable:
            return "Item is no longer available"
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
        default:
            return "Unknown transaction error"
        }
    }
}

// MARK: - Analytics Extension

extension Transaction {
    var analyticsData: [String: Any] {
        [
            "transaction_id": id,
            "buyer_id": buyer.id,
            "seller_id": seller.id,
            "item_id": item.id,
            "amount": amount,
            "currency": currency,
            "status": status.rawValue,
            "payment_method": paymentMethod.rawValue,
            "created_at": createdAt,
            "completed_at": completedAt as Any,
            "canceled_at": canceledAt as Any,
            "platform_fee": fees.platformFee,
            "processing_fee": fees.paymentProcessingFee,
            "shipping_fee": fees.shippingFee,
            "has_dispute": disputeId != nil,
            "has_refund": refundId != nil,
            "rating": rating?.rating as Any
        ]
    }
}