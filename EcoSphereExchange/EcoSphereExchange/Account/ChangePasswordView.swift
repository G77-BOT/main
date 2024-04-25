//
//  ChangePasswordView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-04.
//
import SwiftUI

// View for Change Password
struct ChangePasswordView: View {
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        Form {
            Section {
                SecureField("Old Password", text: $oldPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("New Password", text: $newPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Section {
                Button(action: {
                    // Action to change password
                }) {
                    Text("Change Password")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .navigationTitle("Change Password")
        .listStyle(GroupedListStyle())
    }
}
