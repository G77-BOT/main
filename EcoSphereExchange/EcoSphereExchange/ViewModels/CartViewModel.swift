import Foundation
import Combine
import SwiftData

@MainActor
final class CartViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var cartItems: [CartItem] = []
    @Published var subtotal: Double = 0
    @Published var tax: Double = 0
    @Published var shippingCost: Double = 0
    @Published var total: Double = 0
    @Published var isLoading = false
    @Published var error: Error?
    @Published var checkoutState: CheckoutState = .idle
    @Published var selectedPaymentMethod: PaymentMethod?
    @Published var selectedShippingMethod: ShippingMethod?
    
    // MARK: - Private Properties
    
    private let analyticsManager = AnalyticsManager.shared
    private let securityProvider = SecurityProvider.shared
    private let paymentHandler = PaymentHandler.shared
    private let taxRate = 0.08 // 8% tax rate
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        loadCart()
    }
    
    // MARK: - Public Methods
    
    func addToCart(_ item: Item, quantity: Int = 1) async {
        do {
            guard item.quantity >= quantity else {
                throw CartError.insufficientStock
            }
            
            if let existingItem = cartItems.first(where: { $0.item.id == item.id }) {
                try await updateQuantity(for: existingItem, quantity: existingItem.quantity + quantity)
            } else {
                let cartItem = CartItem(item: item, quantity: quantity)
                cartItems.append(cartItem)
            }
            
            updateTotals()
            try await saveCart()
            trackAddToCart(item: item, quantity: quantity)
            
        } catch {
            self.error = error
            trackError(error)
        }
    }
    
    func removeFromCart(_ item: CartItem) async {
        do {
            cartItems.removeAll { $0.item.id == item.item.id }
            updateTotals()
            try await saveCart()
            trackRemoveFromCart(item: item.item)
            
        } catch {
            self.error = error
            trackError(error)
        }
    }
    
    func updateQuantity(for item: CartItem, quantity: Int) async throws {
        guard quantity > 0 else {
            await removeFromCart(item)
            return
        }
        
        guard item.item.quantity >= quantity else {
            throw CartError.insufficientStock
        }
        
        if let index = cartItems.firstIndex(where: { $0.item.id == item.item.id }) {
            cartItems[index].quantity = quantity
            updateTotals()
            try await saveCart()
            trackUpdateQuantity(item: item.item, quantity: quantity)
        }
    }
    
    func clearCart() async {
        do {
            cartItems.removeAll()
            updateTotals()
            try await saveCart()
            trackClearCart()
            
        } catch {
            self.error = error
            trackError(error)
        }
    }
    
    func checkout() async throws {
        guard !cartItems.isEmpty else {
            throw CartError.emptyCart
        }
        
        guard let paymentMethod = selectedPaymentMethod else {
            throw CartError.noPaymentMethod
        }
        
        guard let shippingMethod = selectedShippingMethod else {
            throw CartError.noShippingMethod
        }
        
        do {
            checkoutState = .processing
            
            // Verify stock availability
            try await verifyStockAvailability()
            
            // Create order
            let order = try await createOrder(
                paymentMethod: paymentMethod,
                shippingMethod: shippingMethod
            )
            
            // Process payment
            try await processPayment(for: order)
            
            // Update inventory
            try await updateInventory()
            
            // Clear cart
            await clearCart()
            
            checkoutState = .completed(order)
            trackCheckoutSuccess(order: order)
            
        } catch {
            checkoutState = .failed(error)
            trackCheckoutFailure(error: error)
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor cart changes
        $cartItems
            .sink { [weak self] _ in
                self?.updateTotals()
            }
            .store(in: &cancellables)
    }
    
    private func loadCart() {
        do {
            if let savedCart = try CartStorage.shared.loadCart() {
                cartItems = savedCart
                updateTotals()
            }
        } catch {
            self.error = error
            trackError(error)
        }
    }
    
    private func saveCart() async throws {
        try await CartStorage.shared.saveCart(cartItems)
    }
    
    private func updateTotals() {
        subtotal = cartItems.reduce(0) { $0 + ($1.item.price * Double($1.quantity)) }
        tax = subtotal * taxRate
        shippingCost = calculateShippingCost()
        total = subtotal + tax + shippingCost
    }
    
    private func calculateShippingCost() -> Double {
        guard let shippingMethod = selectedShippingMethod else {
            return 0
        }
        
        // Calculate shipping cost based on items and selected method
        return shippingMethod.calculateCost(for: cartItems)
    }
    
    private func verifyStockAvailability() async throws {
        for item in cartItems {
            guard item.item.quantity >= item.quantity else {
                throw CartError.insufficientStock
            }
        }
    }
    
    private func createOrder(
        paymentMethod: PaymentMethod,
        shippingMethod: ShippingMethod
    ) async throws -> Order {
        // Create order from cart items
        return Order(
            buyer: UserSession.shared.user!,
            items: cartItems.map { OrderItem(
                id: UUID().uuidString,
                product: $0.item,
                quantity: $0.quantity,
                pricePerUnit: $0.item.price
            )},
            shippingAddress: UserSession.shared.user!.location!,
            paymentInfo: PaymentInfo(
                method: paymentMethod,
                transactionId: nil,
                status: .pending,
                lastFour: nil,
                billingAddress: nil
            ),
            shippingMethod: shippingMethod
        )
    }
    
    private func processPayment(for order: Order) async throws {
        try await paymentHandler.processPayment(
            amount: order.total,
            currency: "USD",
            paymentMethod: order.paymentInfo.method
        )
    }
    
    private func updateInventory() async throws {
        for item in cartItems {
            try await ItemService.shared.updateQuantity(
                item: item.item,
                quantity: item.item.quantity - item.quantity
            )
        }
    }
    
    // MARK: - Analytics
    
    private func trackAddToCart(item: Item, quantity: Int) {
        analyticsManager.trackEvent(.addToCart(
            itemId: item.id,
            quantity: quantity,
            price: item.price
        ))
    }
    
    private func trackRemoveFromCart(item: Item) {
        analyticsManager.trackEvent(.removeFromCart(
            itemId: item.id
        ))
    }
    
    private func trackUpdateQuantity(item: Item, quantity: Int) {
        analyticsManager.trackEvent(.updateCartQuantity(
            itemId: item.id,
            quantity: quantity
        ))
    }
    
    private func trackClearCart() {
        analyticsManager.trackEvent(.clearCart(
            itemCount: cartItems.count,
            total: total
        ))
    }
    
    private func trackCheckoutSuccess(order: Order) {
        analyticsManager.trackEvent(.checkoutComplete(
            orderId: order.id,
            total: order.total,
            itemCount: order.items.count
        ))
    }
    
    private func trackCheckoutFailure(error: Error) {
        analyticsManager.trackEvent(.checkoutFailed(
            error: error,
            cartTotal: total,
            itemCount: cartItems.count
        ))
    }
    
    private func trackError(_ error: Error) {
        analyticsManager.trackError(error)
    }
}

// MARK: - Supporting Types

struct CartItem: Identifiable, Codable {
    let id: String
    let item: Item
    var quantity: Int
    
    init(item: Item, quantity: Int) {
        self.id = UUID().uuidString
        self.item = item
        self.quantity = quantity
    }
}

enum CheckoutState: Equatable {
    case idle
    case processing
    case completed(Order)
    case failed(Error)
    
    static func == (lhs: CheckoutState, rhs: CheckoutState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.processing, .processing):
            return true
        case (.completed(let lhsOrder), .completed(let rhsOrder)):
            return lhsOrder.id == rhsOrder.id
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

enum CartError: LocalizedError {
    case insufficientStock
    case emptyCart
    case noPaymentMethod
    case noShippingMethod
    case invalidQuantity
    case paymentFailed
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientStock:
            return "Insufficient stock available"
        case .emptyCart:
            return "Cart is empty"
        case .noPaymentMethod:
            return "Please select a payment method"
        case .noShippingMethod:
            return "Please select a shipping method"
        case .invalidQuantity:
            return "Invalid quantity specified"
        case .paymentFailed:
            return "Payment processing failed"
        case .saveFailed:
            return "Failed to save cart"
        }
    }
}

// MARK: - Cart Storage

actor CartStorage {
    static let shared = CartStorage()
    
    private let storage = SecureStorage.shared
    private let storageKey = "cart_items"
    
    func loadCart() throws -> [CartItem]? {
        try storage.retrieve(forKey: storageKey)
    }
    
    func saveCart(_ items: [CartItem]) throws {
        try storage.store(items, forKey: storageKey)
    }
    
    func clearCart() throws {
        try storage.delete(key: storageKey)
    }
}