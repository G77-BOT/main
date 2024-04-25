//
//  ContentView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-03-24.
//

import SwiftUI
import SwiftData
import SafariServices
import Combine // Import Combine for Timer functionality
import os.log

// Define a custom subsystem for your logs
private let loggerSubsystem = "com.example.ContentView"
// Create a custom category for your logs
private let loggerCategory = "viewLifecycle"

// Model for User Information
struct User {
    var name: String
    var phoneNumber: String
    var email: String
    var username: String
    var password: String
    var confirmPassword: String
    var address: String
}

// Model for Order Details
struct Order {
    var id = UUID()
    var product: String
    var price: Double
    var quantity: Int
}

// Model for Technology Article
struct TechnologyArticle: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let imageUrl: String?
    let link: URL?
}

// Define your logo image
let logoImageName = "Zpp.img"

struct ContentView: View {
    enum ActiveSheet: Identifiable {
        case login, signup
        
        var id: Int {
            hashValue
        }
    }
    
    @State private var showContent = false
    @State private var countdown = 5 // Initial countdown value
    @State private var activeSheet: ActiveSheet?
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect() // Timer publisher
    
    var body: some View {
        Group {
            if showContent {
                TabView {
                    BlogPostListView()
                        .tabItem {
                            Label("Blog", systemImage: "book")
                        }
                    
                    TechnologyArticleListView()
                        .tabItem {
                            Label("Technology", systemImage: "laptopcomputer")
                        }
                    
                    MarketView() // Replaced CompanyListView with MarketView
                        .tabItem {
                            Label("Market", systemImage: "building.2")
                        }
                    
                    AccountView()
                        .tabItem {
                            Label("Account", systemImage: "person.crop.circle")
                        }
                }
                .background(
                    Image(logoImageName) // Display logo as background image
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                        .opacity(0.5) // Adjust opacity as needed
                )
            } else {
                SplashScreen(countdown: $countdown) { // Show SplashScreen
                    withAnimation {
                        self.showContent = true
                    }
                }
            }
        }
        .onReceive(timer) { _ in // Timer to update countdown
            if self.countdown > 0 {
                self.countdown -= 1
            } else {
                withAnimation {
                    self.showContent = true
                }
            }
        }
        .onAppear {
            // Log the appearance of the ContentView
            os_log("ContentView appeared.", log: OSLog(subsystem: loggerSubsystem, category: loggerCategory), type: .info)
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .login:
                LoginView()
            case .signup:
                SignupView()
            }
        }
        .onAppear {
            activeSheet = .login
        }
        .onAppear {
            activeSheet = .signup
        }
    }
}
struct SplashScreen: View {
    @Binding var countdown: Int // Binding for countdown
    
    var onTap: () -> Void
    
    var body: some View {
        ZStack {
            Color.purple // Set the color of the paper-like background
                .edgesIgnoringSafeArea(.all)
                .opacity(0.5) // Adjust opacity as needed
            
            VStack {
                Spacer()
                Text("Countdown: \(countdown)") // Display countdown
                    .font(.headline)
                    .padding(.top, 20)
            }
            
            Image(logoImageName) // Display logo
                .resizable()
                .scaledToFit()
                .frame(width: 400, height: 800) // Adjust size as needed
                .onTapGesture {
                    onTap() // Execute onTap closure when logo is clicked
                }
        }
    }
}

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @ObservedObject private var userService = UserService.shared
    
    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .padding()
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .padding()
            
            Button("Login") {
                userService.login(username: username, password: password)
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
            .padding()
        }
        .alert(isPresented: $userService.isLoggedIn) {
            Alert(title: Text("Welcome"), message: Text("You are logged in as \(userService.currentUser?.username ?? "")"), dismissButton: .default(Text("OK")))
        }
    }
}


struct SignupView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @ObservedObject private var userService = UserService.shared
    
    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .padding()
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .padding()
            
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
            
            Button("Sign Up") {
                guard password == confirmPassword else {
                    // Passwords don't match, show an error
                    return
                }
                let newUser = User(name: "", phoneNumber: "", email: "", username: username, password: password, confirmPassword: confirmPassword, address: "")
                userService.signup(user: newUser)
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.green)
            .cornerRadius(10)
            .padding()
        }
        .alert(isPresented: $userService.isLoggedIn) {
            Alert(title: Text("Welcome"), message: Text("You are logged in as \(userService.currentUser?.username ?? "")"), dismissButton: .default(Text("OK")))
        }
    }
}







