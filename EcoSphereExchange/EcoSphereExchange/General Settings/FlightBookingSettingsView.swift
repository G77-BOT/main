//
//  FlightBookingSettingsView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import SwiftUI

struct FlightBookingSettingsView: View {
    @State private var aiBookingEnabled: Bool = true
    @State private var privacyEnabled: Bool = false
    @State private var receiptList: [Receipt] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI Flight Booking")) {
                    Toggle("Enable AI Booking", isOn: $aiBookingEnabled)
                    if aiBookingEnabled {
                        // Add AI flight booking settings as needed
                    }
                }
                
                Section(header: Text("Privacy Settings")) {
                    Toggle("Enable Privacy", isOn: $privacyEnabled)
                    if privacyEnabled {
                        // Add privacy settings as needed
                    }
                }
                
                Section(header: Text("Receipts")) {
                    if receiptList.isEmpty {
                        Text("No receipts available")
                    } else {
                        List(receiptList) { receipt in
                            Text(receipt.title)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        // Action to save flight booking settings
                    }) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Flight Booking Settings")
        }
    }
}

struct Receipt: Identifiable {
    let id = UUID()
    let title: String
    // Add more properties as needed
}
