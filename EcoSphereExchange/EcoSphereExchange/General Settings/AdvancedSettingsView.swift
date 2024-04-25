//
//  AdvancedSettingsView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import SwiftUI

struct AdvancedSettingsView: View {
    @State private var personalizedRecommendationsEnabled: Bool = true
    @State private var autoTaggingEnabled: Bool = false
    @State private var aiAssistedCustomerSupport: Bool = true
    @State private var aiLanguageProcessing: Bool = false
    @State private var shippingOptions: [ShippingOption] = []
    @State private var paymentMethods: [PaymentMethod] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personalized Recommendations")) {
                    Toggle("Enable Personalized Recommendations", isOn: $personalizedRecommendationsEnabled)
                }
                
                Section(header: Text("Auto Tagging")) {
                    Toggle("Enable Auto Tagging", isOn: $autoTaggingEnabled)
                }
                
                Section(header: Text("AI Assisted Customer Support")) {
                    Toggle("Enable AI Assisted Support", isOn: $aiAssistedCustomerSupport)
                }
                
                Section(header: Text("AI Language Processing")) {
                    Toggle("Enable AI Language Processing", isOn: $aiLanguageProcessing)
                }
                
                Section(header: Text("Shipping Options")) {
                    if shippingOptions.isEmpty {
                        Text("No shipping options available")
                    } else {
                        ForEach(shippingOptions) { option in
                            Text(option.name)
                        }
                    }
                }
                
                Section(header: Text("Payment Methods")) {
                    if paymentMethods.isEmpty {
                        Text("No payment methods available")
                    } else {
                        ForEach(paymentMethods) { method in
                            Text(method.name)
                        }
                    }
                }
                
                Section(header: Text("Advanced Options")) {
                    // Add more advanced settings options here
                }
            }
            .navigationTitle("Advanced Settings")
        }
    }
}

struct ShippingOption: Identifiable {
    let id = UUID()
    let name: String
    // Add more properties as needed
}

struct PaymentMethod: Identifiable {
    let id = UUID()
    let name: String
    // Add more properties as needed
}



