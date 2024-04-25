//
//  PaymentProcessor.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-17.
//

import Foundation
import PassKit

enum PaymentError: Error {
    case insufficientFunds
    case paymentDeclined
    case connectionError
    case unknownError
}

struct PaymentResult: Identifiable {
    let id = UUID()
    let success: Bool
    let errorMessage: String?
}

class PaymentProcessor: NSObject, PKPaymentAuthorizationViewControllerDelegate {
    static let shared = PaymentProcessor()
    
    private override init() {}
    
    // Simulate processing payment asynchronously
    func processPayment(totalAmount: Double, paymentMethod: String, completion: @escaping (PaymentResult) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let isSuccess = Bool.random()
            
            if isSuccess {
                // Save purchase data here
                let saved = self.savePurchaseData(paymentMethod: paymentMethod, totalAmount: totalAmount)
                
                if saved {
                    completion(PaymentResult(success: true, errorMessage: nil))
                } else {
                    completion(PaymentResult(success: false, errorMessage: "Failed to save purchase data"))
                }
            } else {
                let error: PaymentError = Bool.random() ? .insufficientFunds : .paymentDeclined
                let errorMessage = self.errorMessage(for: error)
                completion(PaymentResult(success: false, errorMessage: errorMessage))
            }
        }
    }
    
    // Save purchase data
    private func savePurchaseData(paymentMethod: String, totalAmount: Double) -> Bool {
        // Replace this with your actual saving logic
        // For example, you can save the purchase details to a database or user defaults
        // Here's a sample implementation using UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(paymentMethod, forKey: "LastPaymentMethod")
        defaults.set(totalAmount, forKey: "LastPaymentAmount")
        
        // Check if data is saved successfully
        return defaults.synchronize()
    }
    
    // Process payment using Apple Pay
    func processApplePayPayment(totalAmount: Double, completion: @escaping (PaymentResult) -> Void) {
        // Check if Apple Pay is available
        if PKPaymentAuthorizationViewController.canMakePayments() {
            let request = PKPaymentRequest()
            request.merchantIdentifier = "merchant.io.designcode.PureLifeYogi"
            request.countryCode = "US"
            request.currencyCode = "USD"
            request.supportedNetworks = [.visa, .masterCard, .amex]
            request.merchantCapabilities = .threeDSecure
            
            let item = PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(value: totalAmount))
            request.paymentSummaryItems = [item]
            
            let viewController = PKPaymentAuthorizationViewController(paymentRequest: request)
            
            if let viewController = viewController {
                viewController.delegate = self
                // Present the Apple Pay view controller
                // YourViewController.present(viewController, animated: true, completion: nil)
            } else {
                completion(PaymentResult(success: false, errorMessage: "Failed to create Apple Pay controller"))
            }
        } else {
            completion(PaymentResult(success: false, errorMessage: "Apple Pay is not available"))
        }
    }
    
    // Provides appropriate error message for different payment errors
    private func errorMessage(for error: PaymentError) -> String {
        switch error {
        case .insufficientFunds:
            return "Insufficient funds. Please use a different payment method."
        case .paymentDeclined:
            return "Payment declined. Please check your card details and try again."
        case .connectionError:
            return "Connection error. Please try again later."
        case .unknownError:
            return "An unknown error occurred. Please try again later."
        }
    }
    
    // Process payment with retry mechanism
    func processPaymentWithRetry(totalAmount: Double, paymentMethod: String, maxAttempts: Int, retryInterval: TimeInterval, completion: @escaping (PaymentResult) -> Void) {
        var attemptCount = 0
        
        func processPayment() {
            attemptCount += 1
            
            self.processPayment(totalAmount: totalAmount, paymentMethod: paymentMethod) { result in
                if result.success || attemptCount >= maxAttempts {
                    completion(result)
                } else {
                    DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                        processPayment()
                    }
                }
            }
        }
        
        processPayment()
    }
    
    // Process payment with logging
    func processPaymentWithLogging(totalAmount: Double, paymentMethod: String, completion: @escaping (PaymentResult) -> Void) {
        print("Starting payment processing for \(paymentMethod)...")
        
        processPayment(totalAmount: totalAmount, paymentMethod: paymentMethod) { result in
            if result.success {
                print("Payment successful for \(paymentMethod).")
            } else {
                print("Payment failed for \(paymentMethod). Error: \(result.errorMessage ?? "Unknown error")")
            }
            
            completion(result)
        }
    }
    
    // Handle payment authorization result for Apple Pay
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        // Dismiss the Apple Pay view controller
        // controller.dismiss(animated: true, completion: nil)
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // Process the payment using the payment token
        _ = payment.token
        // Send payment token to your server for processing
        // After processing, call completion with appropriate result
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
}
