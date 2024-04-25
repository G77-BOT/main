//
//  ECommerceSettingsView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import SwiftUI

struct ECommerceSettingsView: View {
    @State private var aiRecommendationsEnabled: Bool = true
    @State private var personalizedOffersEnabled: Bool = true
    @State private var notificationPreferences: [NotificationPreference] = [
        NotificationPreference(title: "Promotions"),
        NotificationPreference(title: "New Arrivals"),
        NotificationPreference(title: "Order Updates")
    ]
    
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
                
                Section(header: Text("Notification Preferences")) {
                    ForEach(notificationPreferences) { preference in
                        NotificationPreferenceRow(preference: preference)
                    }
                }
                
                Section {
                    Button(action: {
                        // Action to save E-commerce settings
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
            .navigationTitle("E-commerce Settings")
        }
    }
}

struct AIRecommendationsSettingsView: View {
    var body: some View {
        VStack {
            Text("AI Recommendations Settings")
                .font(.headline)
            
            // Add AI recommendations settings UI components
        }
    }
}

struct PersonalizedOffersSettingsView: View {
    var body: some View {
        VStack {
            Text("Personalized Offers Settings")
                .font(.headline)
            
            // Add personalized offers settings UI components
        }
    }
}

struct NotificationPreference: Identifiable {
    let id = UUID()
    let title: String
    // Add more properties as needed
}

struct NotificationPreferenceRow: View {
    var preference: NotificationPreference
    
    var body: some View {
        Toggle(preference.title, isOn: .constant(true))
    }
}
