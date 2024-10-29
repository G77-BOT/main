import SwiftUI
import SwiftData

struct CartView: View {
    @StateObject private var viewModel = CartViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.cartItems.isEmpty {
                    emptyCartView
                } else {
                    cartContent
                }
            }
            .navigationTitle("Cart")
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
            .sheet(isPresented: $showingCheckout) {
                CheckoutView(viewModel: viewModel)
            }
        }
    }
    
    private var emptyCartView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Your cart is empty")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Start shopping to add items to your cart")
                .foregroundColor(.secondary)
            
            NavigationLink {
                ItemListView()
            } label: {
                Text("Browse Items")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var cartContent: some View {
        VStack(spacing: 0) {
            // Cart Items List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.cartItems) { item in
                        CartItemRow(
                            item: item,
                            onQuantityChange: { quantity in
                                Task {
                                    try? await viewModel.updateQuantity(for: item, quantity: quantity)
                                }
                            },
                            onRemove: {
                                Task {
                                    await viewModel.removeFromCart(item)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            
            // Cart Summary
            cartSummary
            
            // Checkout Button
            checkoutButton
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear Cart") {
                    Task {
                        await viewModel.clearCart()
                    }
                }
                .foregroundColor(.red)
            }
        }
    }
    
    private var cartSummary: some View {
        VStack(spacing: 12) {
            Divider()
            
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(formatPrice(viewModel.subtotal))
                }
                
                HStack {
                    Text("Tax")
                    Spacer()
                    Text(formatPrice(viewModel.tax))
                }
                
                HStack {
                    Text("Shipping")
                    Spacer()
                    Text(formatPrice(viewModel.shippingCost))
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(formatPrice(viewModel.total))
                        .font(.headline)
                }
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
    }
    
    private var checkoutButton: some View {
        Button {
            showingCheckout = true
        } label: {
            Text("Proceed to Checkout")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
        }
        .padding()
        .disabled(viewModel.cartItems.isEmpty)
    }
    
    // MARK: - Helper Functions
    
    private func formatPrice(_ price: Double) -> String {
        return String(format: "$%.2f", price)
    }
    
    // MARK: - Private Properties
    
    @State private var showingError = false
    @State private var showingCheckout = false
}

struct CartItemRow: View {
    let item: CartItem
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Item Image
            AsyncImage(url: URL(string: item.item.images.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Item Details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.item.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(item.item.formattedPrice)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                
                // Quantity Stepper
                HStack {
                    Button {
                        if item.quantity > 1 {
                            onQuantityChange(item.quantity - 1)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .disabled(item.quantity <= 1)
                    
                    Text("\(item.quantity)")
                        .frame(minWidth: 30)
                        .font(.headline)
                    
                    Button {
                        onQuantityChange(item.quantity + 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(item.quantity >= item.item.quantity)
                }
                .foregroundColor(.accentColor)
            }
            
            Spacer()
            
            // Remove Button
            Button {
                onRemove()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CheckoutView: View {
    @ObservedObject var viewModel: CartViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Shipping Address
                Section("Shipping Address") {
                    // Add shipping address form
                }
                
                // Payment Method
                Section("Payment Method") {
                    Picker("Payment Method", selection: $viewModel.selectedPaymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(Optional(method))
                        }
                    }
                }
                
                // Shipping Method
                Section("Shipping Method") {
                    Picker("Shipping Method", selection: $viewModel.selectedShippingMethod) {
                        ForEach(availableShippingMethods, id: \.carrier) { method in
                            Text("\(method.carrier) - \(method.service)").tag(Optional(method))
                        }
                    }
                }
                
                // Order Summary
                Section("Order Summary") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(formatPrice(viewModel.subtotal))
                    }
                    
                    HStack {
                        Text("Tax")
                        Spacer()
                        Text(formatPrice(viewModel.tax))
                    }
                    
                    HStack {
                        Text("Shipping")
                        Spacer()
                        Text(formatPrice(viewModel.shippingCost))
                    }
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(formatPrice(viewModel.total))
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Place Order") {
                        placeOrder()
                    }
                    .disabled(!canPlaceOrder)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Private Properties
    
    @State private var showingError = false
    
    private var canPlaceOrder: Bool {
        viewModel.selectedPaymentMethod != nil &&
        viewModel.selectedShippingMethod != nil
    }
    
    private var availableShippingMethods: [ShippingMethod] {
        [
            ShippingMethod(carrier: "Standard", service: "Ground", estimatedDays: 5, baseRate: 5.99),
            ShippingMethod(carrier: "Express", service: "2-Day", estimatedDays: 2, baseRate: 12.99),
            ShippingMethod(carrier: "Priority", service: "Next Day", estimatedDays: 1, baseRate: 24.99)
        ]
    }
    
    // MARK: - Private Methods
    
    private func formatPrice(_ price: Double) -> String {
        return String(format: "$%.2f", price)
    }
    
    private func placeOrder() {
        Task {
            do {
                try await viewModel.checkout()
                dismiss()
            } catch {
                showingError = true
            }
        }
    }
}

#Preview {
    CartView()
}
