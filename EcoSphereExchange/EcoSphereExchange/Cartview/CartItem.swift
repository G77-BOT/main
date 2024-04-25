//
//  CartItem.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-06.
//


import SwiftUI

// Define CartItem
class CartItem: Identifiable {
    let id = UUID()
    let product: Product
    var quantity: Int
    var size: String?
    var color: String?
    var discount: Double
    var shippingDetails: ShippingDetails?
    
    init(product: Product, quantity: Int, size: String? = nil, color: String? = nil, discount: Double = 0.0, shippingDetails: ShippingDetails? = nil) {
        self.product = product
        self.quantity = quantity
        self.size = size
        self.color = color
        self.discount = discount
        self.shippingDetails = shippingDetails
    }
    
    // Add totalPrice property
    var totalPrice: Double {
        // Implement your logic to calculate the total price of the item
        return Double(quantity) * product.price * (1 - discount)
    }
}

// Define ShippingDetails if needed
struct ShippingDetails {
    // Add shipping details properties
}

// Define CartItemRow
struct CartItemRow: View {
    let cartItem: CartItem
    let addItemToCart: () -> Void // Closure to add item to cart
    
    var body: some View {
        HStack {
            cartItem.product.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .padding()
            
            VStack(alignment: .leading) {
                Text(cartItem.product.name)
                    .font(.headline)
                
                Text("$\(String(format: "%.2f", cartItem.totalPrice))")
                    .font(.subheadline)
            }
            
            Spacer()
            
            Button(action: addItemToCart) { // Call the addItemToCart closure
                Image(systemName: "cart.badge.plus")
                    .foregroundColor(.blue)
            }
            .padding(.trailing)
        }
    }
}
