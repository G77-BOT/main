//
//  CartView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-06.
//


import SwiftUI

// Define Cart
class Cart: ObservableObject {
    @Published var items: [CartItem] = []
    
    var totalPrice: Double {
        items.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }
    
    func addItem(_ product: Product, quantity: Int) {
        guard quantity > 0 else { return }
        
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += quantity
        } else {
            items.append(CartItem(product: product, quantity: quantity))
        }
    }
    
    func removeItem(at index: Int) {
        items.remove(at: index)
    }
    
    func removeAllItems() {
        items.removeAll()
    }
}

// Manager for Cart
class ShoppingCart: ObservableObject {
    @Published var items: [CartItem] = []
    
    var totalItems: Int {
        items.count
    }
    
    func addItem(_ item: CartItem) {
        items.append(item)
    }
    
    func removeItem(_ item: CartItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
    }
}



struct CheckoutView: View {
    @ObservedObject var cart: Cart
    @State private var isProcessingPayment = false
    @State private var paymentResult: PaymentResult?
    @State private var isApplePaySheetPresented = false
    
    var body: some View {
        VStack {
            List {
                ForEach(cart.items.indices, id: \.self) { index in
                    CheckoutItemRow(item: cart.items[index], index: index, cart: cart)
                }
            }
            
            Spacer()
            
            HStack {
                Text("Total:")
                    .font(.headline)
                Spacer()
                Text("$\(String(format: "%.2f", cart.totalPrice))")
                    .font(.headline)
            }
            .padding()
            
            Button(action: {
                isApplePaySheetPresented = true
            }) {
                Text("Apple Pay")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding()
            .disabled(isProcessingPayment)
            
            Button(action: {
                processPayment()
            }) {
                Text("Credit Card")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding()
            .disabled(isProcessingPayment)
        }
        .navigationBarTitle("Checkout")
        .sheet(isPresented: $isApplePaySheetPresented) {
            ApplePayView(cart: cart)
        }
        .alert(item: $paymentResult) { result in
            Alert(title: Text(result.success ? "Payment Successful" : "Payment Failed"),
                  message: result.errorMessage.map(Text.init),
                  dismissButton: .default(Text("OK")) {
                    if result.success {
                        cart.removeAllItems() // Clear cart after successful payment
                    }
                  })
        }
    }
    
    
    func processPayment() {
        isProcessingPayment = true
        PaymentProcessor.shared.processPayment(totalAmount: cart.totalPrice, paymentMethod: "Credit Card") { result in
            DispatchQueue.main.async {
                isProcessingPayment = false
                paymentResult = result
            }
        }
    }
}



struct CheckoutItemRow: View {
    let item: CartItem
    let index: Int
    @ObservedObject var cart: Cart

    var body: some View {
        HStack {
            item.product.image
                .resizable()
                .frame(width: 50, height: 50)
                .cornerRadius(8)

            VStack(alignment: .leading) {
                Text(item.product.name)
                    .font(.headline)
                Text("Quantity: \(item.quantity)")
                    .font(.subheadline)
            }

            Spacer()

            Text("$\(String(format: "%.2f", item.product.price * Double(item.quantity)))")
                .font(.subheadline)
        }
        .padding()
    }
}

protocol PaymentService {
    func processPayment(totalAmount: Double, completion: @escaping (Result<String, Error>) -> Void)
}

class MockPaymentService: PaymentService {
    func processPayment(totalAmount: Double, completion: @escaping (Result<String, Error>) -> Void) {
        // Simulate a successful payment after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(.success("Payment successful"))
        }
    }
}




// Define Cart and ShoppingCart classes

// MockPaymentService and PaymentProcessor classes




// Usage:
// Assuming you have a Product instance called "product" representing the product to be added to the cart.
// Initialize a Cart instance:
// let cart = Cart()
// Add items to the cart:
// cart.addItem(product, quantity: 2, size: "Large", color: "Red", discount: 0.1)
// Display items in the cart using CartItemRow:
// CartItemRow(item: cart.items[0])

