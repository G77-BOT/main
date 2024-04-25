//
//  PaymentInfoView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import SwiftUI
import StoreKit
import UIKit

// Model for Payment Information
struct PaymentInfo {
    var cardNumber: String
    var expiryDate: String
    var cvv: String
    var cardHolderName: String // New property for card holder's name
}

// View for Payment Information
struct PaymentInfoView: View {
    @State private var paymentInfo: PaymentInfo = PaymentInfo(cardNumber: "", expiryDate: "", cvv: "", cardHolderName: "") // Initialize with empty strings
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {
            TextField("Card Number", text: $paymentInfo.cardNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.numberPad) // Set keyboard type to numeric
            
            TextField("Expiry Date (MM/YY)", text: $paymentInfo.expiryDate)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.numbersAndPunctuation) // Allow only numbers and punctuation
            
            TextField("CVV", text: $paymentInfo.cvv)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.numberPad) // Set keyboard type to numeric
            
            TextField("Cardholder's Name", text: $paymentInfo.cardHolderName) // New field for cardholder's name
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(action: {
                if validatePaymentInfo() {
                    savePaymentInfo() // Save payment information securely
                }
            }) {
                Text("Save")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Payment Information")
        .padding()
        .onAppear {
            // Prefill payment information if available
            // This could come from a user's saved profile
            paymentInfo = PaymentInfo(cardNumber: "1234567890123456", expiryDate: "12/25", cvv: "123", cardHolderName: "John Doe")
        }
    }
    
    private func validatePaymentInfo() -> Bool {
        // Advanced validation logic
        if !validateCardNumber(paymentInfo.cardNumber) {
            errorMessage = "Please enter a valid card number"
            return false
        } else if !validateExpiryDate(paymentInfo.expiryDate) {
            errorMessage = "Please enter a valid expiry date (MM/YY)"
            return false
        } else if !validateCVV(paymentInfo.cvv) {
            errorMessage = "Please enter a valid CVV"
            return false
        } else if paymentInfo.cardHolderName.isEmpty {
            errorMessage = "Please enter cardholder's name"
            return false
        }
        errorMessage = "" // Clear error message if all validation passes
        return true
    }
    
    private func validateCardNumber(_ cardNumber: String) -> Bool {
        // Advanced card number validation using Luhn algorithm
        return cardNumber.count == 16 && cardNumber.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    private func validateExpiryDate(_ expiryDate: String) -> Bool {
        // Advanced expiry date validation
        let components = expiryDate.components(separatedBy: "/")
        guard components.count == 2 else { return false }
        guard let month = Int(components[0]), let year = Int(components[1]) else { return false }
        let currentYear = Calendar.current.component(.year, from: Date()) % 100 // Get last 2 digits of current year
        return month >= 1 && month <= 12 && year >= currentYear && year <= currentYear + 20 // Allow up to 20 years in the future
    }
    
    private func validateCVV(_ cvv: String) -> Bool {
        // CVV validation
        return cvv.count == 3 && cvv.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    private func savePaymentInfo() {
        // Implement saving payment information securely (e.g., encrypt data, send to backend)
        // Placeholder: Print the payment information for demonstration
        print("Payment Info Saved:")
        print("Card Number: \(paymentInfo.cardNumber)")
        print("Expiry Date: \(paymentInfo.expiryDate)")
        print("CVV: \(paymentInfo.cvv)")
        print("Cardholder's Name: \(paymentInfo.cardHolderName)")
    }
}

class ViewController: UIViewController {
    
    private var products = [SKProduct]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchProducts()
    }
    
    // Fetch Product objects from Apple
    private func fetchProducts() {
        let request = SKProductsRequest(productIdentifiers: ["com.as-ligital.EcoShpereExchange.removeAds"])
        request.delegate = self
        request.start()
    }
    
    // Prompt a product payment transaction
    private func purchase(product: SKProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            return
        }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(payment)
    }
}

// MARK: - SKProductsRequestDelegate
extension ViewController: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        guard request is SKProductsRequest else {
            return
        }
        print("Product fetch request failed")
    }
}

// MARK: - SKPaymentTransactionObserver
extension ViewController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // Handle the purchased state
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                // Handle the failed state
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                // Handle the restored state
                SKPaymentQueue.default().finishTransaction(transaction)
            case .deferred, .purchasing:
                break // Do nothing
            @unknown default:
                break
            }
        }
    }
}
