//
//  UserSession.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-07.
//

import SwiftUI

class UserSession: ObservableObject {
    @Published var isLoggedIn = false
    
    func login(username: String, password: String) {
        // You can implement your own authentication logic here
        if username == "admin" && password == "password" {
            isLoggedIn = true
        } else {
            isLoggedIn = false
        }
    }
    
    func signUp(username: String, password: String, email: String, phoneNumber: String, address: String) {
        // You can implement your own user registration logic here
        // For simplicity, let's just print the registration details
        print("New user registered with the following details:")
        print("Username: \(username)")
        print("Password: \(password)")
        print("Email: \(email)")
        print("Phone Number: \(phoneNumber)")
        print("Address: \(address)")
        
        // Perform additional actions like saving to a database or sending confirmation email
    }
    
    func logout() {
        // Clear user-related data or settings
        clearUserData()
        
        // Reset any necessary app state
        resetAppState()
        
        // Navigate to the login screen or another appropriate screen
        navigateToLoginScreen()
        
        // Update isLoggedIn to false
        isLoggedIn = false
    }
    
    // Example functions for clearing user data, resetting app state, and navigating to the login screen
    private func clearUserData() {
        // Clear user settings, cached data, etc.
    }
    
    private func resetAppState() {
        // Reset any app-wide state or variables
    }
    
    private func navigateToLoginScreen() {
        // Code to navigate to the login screen, such as using navigation links or presenting a new view
    }
}
