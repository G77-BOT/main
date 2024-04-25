//
//  AddressSettingsView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import SwiftUI

struct AddressSettingsView: View {
    @State private var address: String = ""
    @State private var isAddressValid: Bool = true
    
    var body: some View {
        VStack {
            Section(header: Text("Address")) {
                TextField("Enter your address", text: $address)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                
                if !isAddressValid {
                    Text("Please enter a valid address")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
            
            Button(action: {
                validateAndSaveAddress()
            }) {
                Text("Save Address")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Address Settings")
    }
    
    private func validateAndSaveAddress() {
        // Perform address validation here (e.g., through an AI-powered address verification service)
        if address.isEmpty {
            isAddressValid = false
        } else {
            // Save the user's address to the database or perform any other necessary actions
            isAddressValid = true
            saveAddress()
        }
    }
    
    private func saveAddress() {
        // Implement address saving logic
    }
}
