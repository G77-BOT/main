//
//  AffiliateSignupView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-07.
//

import SwiftUI

struct AffiliateSignupView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Welcome To More Adavnce Affiliate Program")
                    .font(.title)
                    .fontWeight(.bold)
                
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    // Perform signup logic here...
                    signup()
                }) {
                    Text("Sign Up")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Affiliate Signup")
    }
    
    private func signup() {
        // Implement signup logic here...
        print("Signing up...")
        print("First Name: \(firstName)")
        print("Last Name: \(lastName)")
        print("Email: \(email)")
        print("Password: \(password)")
    }
}

