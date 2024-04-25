//
//  AffiliateProgramSettingsView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import SwiftUI

struct AffiliateProgramSettingsView: View {
    @State private var monthlySales: Double = 0.0
    @State private var advertisementCampaignEnabled: Bool = true
    @State private var showFuturesGrid: Bool = true
    @State private var privacyAgreements: [PrivacyAgreement] = []
    @State private var selectedSetting: AffiliateSetting? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Monthly Sales")) {
                    Text("Total Sales: $\(monthlySales)")
                    Slider(value: $monthlySales, in: 0...10_000, step: 100)
                        .padding(.horizontal)
                }
                
                Section(header: Text("Advertisement Campaign")) {
                    Toggle("Enable Advertisement Campaign", isOn: $advertisementCampaignEnabled)
                }
                
                Section(header: Text("Futures Grid")) {
                    Toggle("Show Futures Grid", isOn: $showFuturesGrid)
                }
                
                Section(header: Text("Privacy Agreements")) {
                    if privacyAgreements.isEmpty {
                        Text("No privacy agreements available")
                    } else {
                        ForEach(privacyAgreements) { agreement in
                            Text(agreement.title)
                        }
                    }
                }
                
                Section(header: Text("Settings")) {
                    NavigationLink(destination: AffiliateSettingView(setting: $selectedSetting)) {
                        Text(selectedSetting?.name ?? "Select Setting")
                    }
                }
                
                Section(header: Text("Privacy")) {
                    NavigationLink(destination: DocumentsView()) {
                        Text("View Documents")
                    }
                }
            }
            .navigationTitle("Affiliate Program Settings")
        }
    }
}

struct AffiliateSetting {
    let id = UUID()
    let name: String
    let description: String
    // Add more properties as needed
}

struct PrivacyAgreement: Identifiable {
    let id = UUID()
    let title: String
    // Add more properties as needed
}

struct DocumentsView: View {
    var body: some View {
        Text("Documents View")
            .navigationTitle("Documents")
    }
}

struct AffiliateSettingView: View {
    @Binding var setting: AffiliateSetting?
    
    var body: some View {
        VStack {
            Text(setting?.name ?? "No Setting Selected")
                .font(.title)
                .padding()
            
            Text(setting?.description ?? "")
                .padding()
            
            // Add UI components for setting details
        }
    }
}


