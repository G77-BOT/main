//
//  PaymentHandler.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-03-25.
//

import Foundation
import PassKit

typealias PaymentCompletionHandler = (Bool) -> Void

class PaymentHandler: NSObject {
    var paymentController: PKPaymentAuthorizationController?
    var paymentSummaryItems = [PKPaymentSummaryItem]()
    var paymentStatus = PKPaymentAuthorizationStatus.failure
    var completionHandler: PaymentCompletionHandler?
    
    static let supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard]
    
    func shippingMethodCalculator() -> [PKShippingMethod] {
        let today = Date()
        let calendar = Calendar.current
        let shippingStart = calendar.date(byAdding: .day, value: 5, to: today)
        let shippingEnd = calendar.date(byAdding: .day, value: 10, to: today)
        
        var shippingMethods = [PKShippingMethod]()
        
        if let shippingStart = shippingStart, let shippingEnd = shippingEnd {
            let startComponents = calendar.dateComponents([.year, .month, .day], from: shippingStart)
            let endComponents = calendar.dateComponents([.year, .month, .day], from: shippingEnd)
            
            let shippingDelivery = PKShippingMethod(label: "Delivery", amount: NSDecimalNumber(string: "0.88"))
            shippingDelivery.dateComponentsRange = PKDateComponentsRange(start: startComponents, end: endComponents)
            shippingDelivery.detail = "Yoga Mat sent to your address"
            shippingDelivery.identifier = "DELIVERY"
            
            // Assuming you have some logic here to calculate shipping methods based on startComponents and endComponents
            
            // Creating sample shipping methods for demonstration
            let standardShipping = PKShippingMethod(label: "Standard Shipping", amount: NSDecimalNumber(value: 5.0))
            standardShipping.detail = "Estimated delivery \(startComponents.month!)/\(startComponents.day!) - \(endComponents.month!)/\(endComponents.day!)"
            
            let expressShipping = PKShippingMethod(label: "Express Shipping", amount: NSDecimalNumber(value: 10.0))
            expressShipping.detail = "Estimated delivery \(startComponents.month!)/\(startComponents.day!) - \(endComponents.month!)/\(endComponents.day!)"
            
            shippingMethods.append(standardShipping)
            shippingMethods.append(expressShipping)
        }
        
        return shippingMethods
    }
    
    func startPayment(products: [Product], total: Int, completion: @escaping PaymentCompletionHandler) {
        completionHandler = completion
        paymentSummaryItems = []
        
        // Create payment summary items for each product
        for product in products {
            let item = PKPaymentSummaryItem(label: product.name, amount: NSDecimalNumber(string: "\(product.price).00"))
            paymentSummaryItems.append(item)
        }
        
        // Add total amount as the last payment summary item
        let totalItem = PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(string: "\(total).00"))
        paymentSummaryItems.append(totalItem)
        
        // Create a single payment request
        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = paymentSummaryItems
        paymentRequest.merchantIdentifier = "merchant.io.designcode.PureLifeYogi"
        paymentRequest.merchantCapabilities = .threeDSecure
        paymentRequest.countryCode = "CA"
        paymentRequest.currencyCode = "CAD"
        paymentRequest.supportedNetworks = PaymentHandler.supportedNetworks
        paymentRequest.shippingType = .delivery
        paymentRequest.shippingMethods = shippingMethodCalculator()
        paymentRequest.requiredShippingContactFields = [.name, .postalAddress]
        
        paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController?.delegate = self
        paymentController?.present(completion: { (presented: Bool) in
            if presented {
                debugPrint("Presented payment controller")
            } else {
                debugPrint("Failed to present payment controller")
            }
        })
    }
}

    
                        

extension PaymentHandler: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        let errors = [Error]()
        let status = PKPaymentAuthorizationStatus.success
        
        self.paymentStatus = status
        completion(PKPaymentAuthorizationResult(status: status, errors: errors))
        
        // Assuming payment processing is successful
        let paymentResult = PKPaymentAuthorizationResult(status: .success, errors: nil)
        
        // Call the completion handler with the payment result
        completion(paymentResult)
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        // Dismiss the payment authorization controller
        controller.dismiss(completion: nil)
    }
    
    func PaymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            DispatchQueue.main.async {
                if self.paymentStatus == .success {
                    if let completionHandler = self.completionHandler {
                        completionHandler(true)
                    }
                    
                } else {
                    if let completionHandler = self.completionHandler {
                        completionHandler(false)
                    }
                }
            }
        }
    }
}
