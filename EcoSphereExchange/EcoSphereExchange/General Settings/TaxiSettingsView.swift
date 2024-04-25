//
//  TaxiSettingsView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import SwiftUI

struct TaxiSettingsView: View {
    @State private var aiRecommendationsEnabled: Bool = true
    @State private var personalizedOffersEnabled: Bool = true
    @State private var couponCode: String = ""
    @State private var rideHistory: [Ride] = [
        Ride(destination: "Airport"),
        Ride(destination: "Downtown"),
        Ride(destination: "Shopping Mall")
    ]
    @State private var customerServiceEnabled: Bool = true

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI Recommendations")) {
                    Toggle("Enable AI Recommendations", isOn: $aiRecommendationsEnabled)
                    if aiRecommendationsEnabled {
                        AIRecommendationsSettingsView()
                    }
                }
                
                Section(header: Text("Personalized Offers")) {
                    Toggle("Enable Personalized Offers", isOn: $personalizedOffersEnabled)
                    if personalizedOffersEnabled {
                        PersonalizedOffersSettingsView()
                    }
                }
                
                Section(header: Text("Coupon Code")) {
                    TextField("Enter coupon code", text: $couponCode)
                }
                
                Section(header: Text("Ride History")) {
                    if rideHistory.isEmpty {
                        Text("No ride history available")
                    } else {
                        ForEach(rideHistory) { ride in
                            Text(ride.destination)
                        }
                    }
                }
                
                Section(header: Text("Customer Service")) {
                    Toggle("Enable Customer Service", isOn: $customerServiceEnabled)
                }
                
                Section {
                    Button(action: {
                        // Action to save taxi settings
                        saveTaxiSettings()
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
            .navigationTitle("Taxi Settings")
        }
    }
    
    func saveTaxiSettings() {
        // Implement code to save taxi settings
        // This function will be called when the Save button is tapped
    }
}



struct Ride: Identifiable {
    let id = UUID()
    let destination: String
    // Add more properties as needed
}


