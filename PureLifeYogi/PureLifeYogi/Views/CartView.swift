//
//  CartView.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-03-25.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        ScrollView {
            if cartManager.paymentSuccess {
                Text("Congratulations on your new yoga mats! Remember, just as the mat supports your body during practice, may your practice support your mind, body, and spirit on and off the mat. You'll also receive an email confirmation shortly. Namaste.")
                    .padding()
            } else {
                if cartManager.products.count > 0 {
                    ForEach(cartManager.products, id: \.id) { product in
                        ProductRow(product: product)
                    }
                    
                    HStack {
                        Text("Your cart total is")
                        Spacer()
                        Text("$\(cartManager.total).00")
                            .bold()
                    }
                    .padding()
                    
                    PaymentButton(action: cartManager.pay)
                        .padding()
                } else {
                    Text("Your cart is empty")
                }
            }
        }
        .navigationTitle(Text("My Cart"))
        .padding(.top)
        .onDisappear {
            // Reset paymentSuccess flag when leaving the view
            if cartManager.paymentSuccess {
                cartManager.paymentSuccess = false
            }
        }
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
            .environmentObject(CartManager())
    }
}
