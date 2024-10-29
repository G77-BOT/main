import Foundation
import SwiftData

@Model
final class Wallet: Identifiable {
    let id: UUID
    var balance: Double
    var currency: String
    var isActive: Bool
    var transactions: [Transaction]
    var paymentMethods: [PaymentMethod]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        balance: Double = 0.0,
        currency: String = "USD",
        isActive: Bool = true
    ) {
        self.id = id
        self.balance = balance
        self.currency = currency
        self.isActive = isActive
        self.transactions = []
        self.paymentMethods = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func addFunds(_ amount: Double) throws {
        guard amount > 0 else {
            throw WalletError.invalidAmount
        }
        balance += amount
        addTransaction(.credit, amount: amount, description: "Funds added")
        updatedAt = Date()
    }
    
    func withdrawFunds(_ amount: Double) throws {
        guard amount > 0 else {
            throw WalletError.invalidAmount
        }
        guard amount <= balance else {
            throw WalletError.insufficientFunds
        }
        balance -= amount
        addTransaction(.debit, amount: amount, description: "Funds withdrawn")
        updatedAt = Date()
    }
    
    func addPaymentMethod(_ method: PaymentMethod) {
        paymentMethods.append(method)
        updatedAt = Date()
    }
    
    func removePaymentMethod(id: UUID) {
        paymentMethods.removeAll { $0.id == id }
        updatedAt = Date()
    }
    
    private func addTransaction(_ type: TransactionType, amount: Double, description: String) {
        let transaction = Transaction(
            type: type,
            amount: amount,
            description: description,
            currency: currency
        )
        transactions.append(transaction)
    }
}

struct Transaction: Codable, Identifiable {
    let id: UUID
    let type: TransactionType
    let amount: Double
    let description: String
    let currency: String
    let status: TransactionStatus
    let metadata: [String: String]?
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        type: TransactionType,
        amount: Double,
        description: String,
        currency: String,
        status: TransactionStatus = .completed,
        metadata: [String: String]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.description = description
        self.currency = currency
        self.status = status
        self.metadata = metadata
        self.createdAt = createdAt
    }
}

enum TransactionType: String, Codable {
    case credit
    case debit
}

enum TransactionStatus: String, Codable {
    case pending
    case completed
    case failed
    case cancelled
}

struct PaymentMethod: Codable, Identifiable {
    let id: UUID
    let type: PaymentMethodType
    let provider: String
    let lastFourDigits: String?
    let expiryDate: Date?
    let isDefault: Bool
    let metadata: [String: String]?
    
    init(
        id: UUID = UUID(),
        type: PaymentMethodType,
        provider: String,
        lastFourDigits: String? = nil,
        expiryDate: Date? = nil,
        isDefault: Bool = false,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.provider = provider
        self.lastFourDigits = lastFourDigits
        self.expiryDate = expiryDate
        self.isDefault = isDefault
        self.metadata = metadata
    }
}

enum PaymentMethodType: String, Codable {
    case creditCard
    case debitCard
    case bankAccount
    case digitalWallet
    case cryptocurrency
}

enum WalletError: LocalizedError {
    case insufficientFunds
    case invalidAmount
    case walletInactive
    case invalidCurrency
    case transactionFailed
    case invalidPaymentMethod
    
    var errorDescription: String? {
        switch self {
        case .insufficientFunds:
            return "Insufficient funds in wallet"
        case .invalidAmount:
            return "Invalid transaction amount"
        case .walletInactive:
            return "Wallet is inactive"
        case .invalidCurrency:
            return "Invalid currency"
        case .transactionFailed:
            return "Transaction failed to process"
        case .invalidPaymentMethod:
            return "Invalid payment method"
        }
    }
}