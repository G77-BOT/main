//
//  UserInfoView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-04.
//

import SwiftUI
import os.log

// Define a custom subsystem for your logs
private let loggerSubsystem = "com.example.UserInfoView"
// Create a custom category for your logs
private let loggerCategory = "userInteraction"

// View for User Information
struct UserInfoView: View {
    @State private var user: User
    
    init(user: User) {
        self._user = State(initialValue: user)
    }

    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Name", text: $user.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Phone Number", text: $user.phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Email", text: $user.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Username", text: $user.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("Password", text: $user.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Address", text: $user.address)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Section {
                Button(action: {
                    // Action to save user information
                    saveUserInfo()
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
        .navigationTitle("User Information")
        .listStyle(GroupedListStyle())
    }
    
    private func saveUserInfo() {
        // Save user information logic here
        
        // Example logging
        os_log("User information saved: Name: %@, Phone Number: %@, Email: %@, Username: %@, Password: %@, Address: %@", log: OSLog(subsystem: loggerSubsystem, category: loggerCategory), type: .info, user.name, user.phoneNumber, user.email, user.username, user.password, user.address)
    }
}
