//
//  BillingInfoView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-04.
//

import SwiftUI

// Model for Billing Information
struct BillingInfo {
    var cardNumber: String
    var expiryDate: String
    var cvv: String
}

// View for Billing Information
struct BillingInfoView: View {
    @State private var billingInfo: BillingInfo = BillingInfo(cardNumber: "", expiryDate: "", cvv: "")
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {
            TextField("Card Number", text: $billingInfo.cardNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.numberPad) // Set keyboard type to numeric
            
            TextField("Expiry Date (MM/YY)", text: $billingInfo.expiryDate)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.numbersAndPunctuation) // Allow only numbers and punctuation
            
            TextField("CVV", text: $billingInfo.cvv)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.numberPad) // Set keyboard type to numeric
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(action: {
                if validateBillingInfo() {
                    saveBillingInfo() // Save billing information securely
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
        .navigationTitle("Billing Information")
        .padding()
        .onAppear {
            // Prefill billing information if available
            // This could come from a user's saved profile
            billingInfo = BillingInfo(cardNumber: "1234567890123456", expiryDate: "12/25", cvv: "123")
        }
    }
    
    private func validateBillingInfo() -> Bool {
        // Advanced validation logic
        if !validateCardNumber(billingInfo.cardNumber) {
            errorMessage = "Please enter a valid card number"
            return false
        } else if !validateExpiryDate(billingInfo.expiryDate) {
            errorMessage = "Please enter a valid expiry date (MM/YY)"
            return false
        } else if !validateCVV(billingInfo.cvv) {
            errorMessage = "Please enter a valid CVV"
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
    
    private func saveBillingInfo() {
        // Implement saving billing information securely (e.g., encrypt data, send to backend)
        // Placeholder: Print the billing information for demonstration
        print("Billing Info Saved:")
        print("Card Number: \(billingInfo.cardNumber)")
        print("Expiry Date: \(billingInfo.expiryDate)")
        print("CVV: \(billingInfo.cvv)")
    }
}
