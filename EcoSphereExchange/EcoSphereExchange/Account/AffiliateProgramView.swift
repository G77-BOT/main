//
//  AffiliateProgramView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-04.
//

import SwiftUI

// Model for Affiliate Program Information
struct AffiliateProgram: Codable { // Added Codable conformance
    var programName: String
    var commissionRate: Double
    var totalEarnings: Double
    // Additional properties can be added as needed
}

struct AffiliateProgramView: View {
    @State private var affiliateProgram: AffiliateProgram = AffiliateProgram(programName: "EcoSphere Affiliate Program", commissionRate: 5.0, totalEarnings: 0.0)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Welcome To \(affiliateProgram.programName)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Divider() // Add a divider
                
                AffiliateDetailRow(title: "Program Name:", value: affiliateProgram.programName)
                
                AffiliateDetailRow(title: "Commission Rate:", value: "\(affiliateProgram.commissionRate)%")
                
                AffiliateDetailRow(title: "Total Earnings:", value: "$\(String(format: "%.2f", affiliateProgram.totalEarnings))")
                
                Spacer() // Add some space
                
                // Affiliate signup button
                NavigationLink(destination: AffiliateSignupView()) {
                    Text("Sign Up for Affiliate Program")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
                
                // Save affiliate program data
                Button(action: {
                    // Save affiliate program data to local storage
                    saveAffiliateProgramData()
                }) {
                    Text("Save")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Affiliate Program")
        .onAppear {
            // Load affiliate program data from local storage
            loadAffiliateProgramData()
            calculateTotalEarnings() // Calculate total earnings based on user deals
        }
    }
    
    // Affiliate detail row view
    private struct AffiliateDetailRow: View {
        var title: String
        var value: String
        
        var body: some View {
            HStack {
                Text(title)
                    .fontWeight(.bold)
                Spacer()
                Text(value)
            }
        }
    }
    
    // Function to save affiliate program data to local storage
    private func saveAffiliateProgramData() {
        // In this example, we'll use UserDefaults for local storage
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(affiliateProgram) {
            UserDefaults.standard.set(encoded, forKey: "affiliateProgram")
        }
    }
    
    // Function to load affiliate program data from local storage
    private func loadAffiliateProgramData() {
        // In this example, we'll use UserDefaults for local storage
        if let savedData = UserDefaults.standard.data(forKey: "affiliateProgram") {
            let decoder = JSONDecoder()
            if let loadedProgram = try? decoder.decode(AffiliateProgram.self, from: savedData) {
                affiliateProgram = loadedProgram
            }
        }
    }
    
    // Function to calculate total earnings based on user deals
    private func calculateTotalEarnings() {
        // In this example, we'll use a simple calculation
        // You would replace this with your actual logic
        affiliateProgram.totalEarnings = 1000.0 // For demonstration purposes
    }
}
