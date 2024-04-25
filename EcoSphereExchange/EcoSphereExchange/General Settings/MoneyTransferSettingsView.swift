//
//  MoneyTransferSettingsView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import SwiftUI

struct MoneyTransferSettingsView: View {
    @State private var biometricAuthenticationEnabled: Bool = true
    @State private var emailNotificationsEnabled: Bool = true
    @State private var transactionHistory: [TransactionModel] = []
    @State private var currency: Currency = .usd

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Biometric Authentication")) {
                    Toggle("Enable Biometric Authentication", isOn: $biometricAuthenticationEnabled)
                }
                
                Section(header: Text("Email Notifications")) {
                    Toggle("Enable Email Notifications", isOn: $emailNotificationsEnabled)
                }
                
                Section(header: Text("Transaction History")) {
                    if transactionHistory.isEmpty {
                        Text("No transaction history available")
                    } else {
                        ForEach(transactionHistory) { transaction in
                            Text(transaction.description)
                        }
                    }
                }
                
                Section(header: Text("Currency")) {
                    Picker("Currency", selection: $currency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text(currency.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: {
                        // Action to save money transfer settings
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
            .navigationTitle("Money Transfer Settings")
        }
    }
}

struct TransactionModel: Identifiable {
    let id = UUID()
    let description: String
    // Add more properties as needed
}

enum Currency: String, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    // Add more currencies as needed
}

