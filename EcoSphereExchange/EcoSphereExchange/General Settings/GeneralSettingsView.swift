//
//  GeneralSettingsView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-04.
//

import SwiftUI

struct GeneralSettingsView: View {
    @State private var pushNotificationEnabled: Bool = true
    @State private var darkModeEnabled: Bool = false
    @State private var language: String = "English"
    @State private var currency: String = "USD"
    @State private var showAddressSettings: Bool = false
    @State private var showPrivacySettings: Bool = false
    @State private var showNotificationSettings: Bool = false
    @State private var showGamesSettings: Bool = false
    @State private var showFlightBookingSettings: Bool = false
    @State private var showECommerceSettings: Bool = false
    @State private var showTaxiSettings: Bool = false
    @State private var showMoneyTransferSettings: Bool = false
    @State private var showAffiliateProgramSettings: Bool = false
    @State private var showAdvancedSettings: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preferences")) {
                    Toggle("Push Notifications", isOn: $pushNotificationEnabled)
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                    Picker("Language", selection: $language) {
                        Text("English").tag("English")
                        Text("Spanish").tag("Spanish")
                        Text("French").tag("French")
                        // Add more language options as needed
                    }
                    Picker("Currency", selection: $currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                        // Add more currency options as needed
                    }
                }
                
                Section(header: Text("User Profile")) {
                    NavigationLink(destination: AddressSettingsView()) {
                        Text("Address Settings")
                    }
                }
                
                Section(header: Text("Privacy")) {
                    NavigationLink(destination: PrivacySettingsView()) {
                        Text("Privacy Settings")
                    }
                }
                
                Section(header: Text("Notification Preferences")) {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Text("Notification Settings")
                    }
                }
                
                Section(header: Text("Additional Settings")) {
                    NavigationLink(destination: GamesSettingsView()) {
                        Text("Games Settings")
                    }
                    NavigationLink(destination: FlightBookingSettingsView()) {
                        Text("Flight Booking Settings")
                    }
                    NavigationLink(destination: ECommerceSettingsView()) {
                        Text("E-commerce Settings")
                    }
                    NavigationLink(destination: TaxiSettingsView()) {
                        Text("Taxi Settings")
                    }
                    NavigationLink(destination: MoneyTransferSettingsView()) {
                        Text("Money Transfer Settings")
                    }
                    NavigationLink(destination: AffiliateProgramSettingsView()) {
                        Text("Affiliate Program Settings")
                    }
                }
                
                Section(header: Text("Advanced Settings")) {
                    Button(action: {
                        showAdvancedSettings.toggle()
                    }) {
                        Text("Advanced Settings")
                    }
                }
                
            }
            .navigationTitle("General Settings")
            .sheet(isPresented: $showAdvancedSettings) {
                AdvancedSettingsView()
            }
        }
    }
}

