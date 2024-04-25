//
//  PaymentButton.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-20.
//

import SwiftUI
import PassKit

struct PaymentButton: View {
    var action: () -> Void
    
    var body: some View {
        Representable(action: action)
            .frame(minWidth: 100, maxWidth: 400)
            .frame(height: 45)
            .frame(maxWidth: .infinity)
    }
}

struct PaymentButton_Previews: PreviewProvider {
    static var previews: some View {
        PaymentButton(action: {})
    }
}

extension PaymentButton {
    struct Representable: UIViewRepresentable {
        var action: () -> Void
        
        func makeCoordinator() -> Coordinator {
            Coordinator(action: action)
        }
        
        func makeUIView(context: Context) -> PKPaymentButton {
            let button = PKPaymentButton(paymentButtonType: .checkout, paymentButtonStyle: .automatic)
            button.addTarget(context.coordinator, action: #selector(context.coordinator.callback(_:)), for: .touchUpInside)
            return button
        }
        
        func updateUIView(_ uiView: PKPaymentButton, context: Context) {
            // No need to update the UIView
        }
    }
    
    class Coordinator: NSObject {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
            super.init()
        }
        
        @objc func callback(_ sender: Any) {
            action()
        }
    }
}

struct PayPalButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image("paypal_logo")
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("Pay with PayPal")
            }
            .padding()
            .foregroundColor(.white)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
        }
    }
}

struct PayPalButton_Previews: PreviewProvider {
    static var previews: some View {
        PayPalButton(action: {})
    }
}

extension PayPalButton {
    struct Representable: UIViewRepresentable {
        var action: () -> Void
        
        func makeCoordinator() -> Coordinator {
            Coordinator(action: action)
        }
        
        func makeUIView(context: Context) -> UIButton {
            let button = UIButton(type: .system)
            button.addTarget(context.coordinator, action: #selector(context.coordinator.callback(_:)), for: .touchUpInside)
            return button
        }
        
        func updateUIView(_ uiView: UIButton, context: Context) {
            // No need to update the UIView
        }
    }
    
    class Coordinator: NSObject {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
            super.init()
        }
        
        @objc func callback(_ sender: Any) {
            action()
        }
    }
}

struct ApplePayView: View {
    @ObservedObject var cart: Cart
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Apple Pay View")
                .padding()
            Spacer()
            // Implement Apple Pay Button
            PaymentButton(action: {
                // Checkout with Apple Pay action
            })
            .padding()
            Spacer()
        }
    }
}

struct ApplePayView_Previews: PreviewProvider {
    static var previews: some View {
        ApplePayView(cart: Cart())
    }
}

