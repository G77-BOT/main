//
//  ContentView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-03-24.
//

import SwiftUI
import Combine

class UserService: ObservableObject {
    @Published var isLoggedIn: Bool {
        didSet {
            UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        }
    }
    @Published var currentUser: User? {
        didSet {
            if let user = currentUser {
                let encodedUser = try? JSONEncoder().encode(user)
                UserDefaults.standard.set(encodedUser, forKey: "currentUser")
            } else {
                UserDefaults.standard.removeObject(forKey: "currentUser")
            }
        }
    }
    @Published var users: [User] = [] {
        didSet {
            saveUsers()
        }
    }
    
    let notificationManager = NotificationManager()
    
    init() {
        // Load stored users and current session
        loadUsers()
        if let savedUser = UserDefaults.standard.data(forKey: "currentUser"),
           let decodedUser = try? JSONDecoder().decode(User.self, from: savedUser) {
            self.currentUser = decodedUser
            self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        } else {
            self.currentUser = nil
            self.isLoggedIn = false
        }
    }
    
    func login(username: String, password: String) -> Bool {
        if let user = users.first(where: { $0.username == username && $0.password == password }) {
            currentUser = user
            isLoggedIn = true
            return true
        }
        return false
    }
    
    func signup(user: User) -> Bool {
        if users.contains(where: { $0.username == user.username }) {
            return false // Username already exists
        }
        users.append(user)
        currentUser = user
        isLoggedIn = true
        
        // Schedule default notifications for new users
        notificationManager.scheduleNotification(for: "promotions")
        notificationManager.scheduleNotification(for: "productUpdates")
        
        return true
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
    }
    
    private func loadUsers() {
        if let savedUsersData = UserDefaults.standard.data(forKey: "users"),
           let decodedUsers = try? JSONDecoder().decode([User].self, from: savedUsersData) {
            self.users = decodedUsers
        }
    }
    
    private func saveUsers() {
        if let encodedData = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encodedData, forKey: "users")
        }
    }
}

// Main ContentView with Login and Signup Handling
struct ContentView: View {
    @StateObject private var userService = UserService()
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            if userService.isLoggedIn {
                MainTabView() // Navigate to main content if user is logged in
            } else {
                VStack {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    if isSignUp {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Button(action: {
                        if isSignUp {
                            if password == confirmPassword {
                                let newUser = User(name: "", phoneNumber: "", email: "", username: username, password: password, confirmPassword: confirmPassword, address: "")
                                if !userService.signup(user: newUser) {
                                    errorMessage = "Username already exists!"
                                }
                            } else {
                                errorMessage = "Passwords do not match!"
                            }
                        } else {
                            if !userService.login(username: username, password: password) {
                                errorMessage = "Invalid login credentials!"
                            }
                        }
                    }) {
                        Text(isSignUp ? "Sign Up" : "Login")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                    
                    Button(action: {
                        isSignUp.toggle()
                        errorMessage = nil // Clear errors when switching modes
                    }) {
                        Text(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up")
                    }
                    .padding()
                }
                .padding()
                .navigationTitle(isSignUp ? "Sign Up" : "Login")
            }
        }
        .environmentObject(userService.notificationManager)
        .alert(isPresented: $userService.isLoggedIn) {
            Alert(title: Text("Welcome"), message: Text("You are logged in as \(userService.currentUser?.username ?? "")"), dismissButton: .default(Text("OK")))
        }
    }
}

// Main Tab View after Login
struct MainTabView: View {
    var body: some View {
        TabView {
            BlogPostListView()
                .tabItem {
                    Label("Blog", systemImage: "book")
                }
            
            TechnologyArticleListView()
                .tabItem {
                    Label("Technology", systemImage: "laptopcomputer")
                }
            
            MarketView()
                .tabItem {
                    Label("Market", systemImage: "building.2")
                }
            
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
        }
    }
}

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    func trackEvent(_ name: String, parameters: [String: Any]) {
        // Implement analytics tracking
        let timestamp = Date()
        let userId = UserDefaults.standard.string(forKey: "userId")
        // Send to analytics service
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

