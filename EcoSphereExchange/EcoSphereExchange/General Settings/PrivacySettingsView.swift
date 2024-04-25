//
//  PrivacySettingsView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import SwiftUI

struct PrivacySettingsView: View {
    @State private var personalizedAdsEnabled: Bool = true
    @State private var dataCollectionEnabled: Bool = true
    @State private var locationTrackingEnabled: Bool = false
    @State private var consentAgreementAccepted: Bool = false
    @State private var isShowingConsentAgreement: Bool = false
    
    var body: some View {
        VStack {
            Section(header: Text("Personalized Ads")) {
                Toggle("Enable Personalized Ads", isOn: $personalizedAdsEnabled)
                    .font(.headline)
            }
            .padding(.vertical)
            
            Section(header: Text("Data Collection")) {
                Toggle("Enable Data Collection", isOn: $dataCollectionEnabled)
                    .font(.headline)
            }
            .padding(.vertical)
            
            Section(header: Text("Location Tracking")) {
                Toggle("Enable Location Tracking", isOn: $locationTrackingEnabled)
                    .font(.headline)
            }
            .padding(.vertical)
            
            Button(action: {
                isShowingConsentAgreement = true
            }) {
                Text("View Consent Agreement")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            
            Spacer()
        }
        .sheet(isPresented: $isShowingConsentAgreement) {
            ConsentAgreementView(consentAgreementAccepted: $consentAgreementAccepted)
        }
        .navigationTitle("Privacy Settings")
    }
}

struct ConsentAgreementView: View {
    @Binding var consentAgreementAccepted: Bool
    
    var body: some View {
        VStack {
            Text("Privacy Consent Agreement")
                .font(.title)
                .padding()
            
            // Display the consent agreement text here
            
            Button(action: {
                consentAgreementAccepted = true
            }) {
                Text("I Agree")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}
