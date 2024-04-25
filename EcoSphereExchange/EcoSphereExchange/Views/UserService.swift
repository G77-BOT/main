//
//  UserService.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-19.
//

import SwiftUI
import CoreData
import Combine


class UserService: ObservableObject {
    static let shared = UserService()
    
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    
    private var users: [User] = []
    
    init() {
        // Load users from storage or database
        loadUsers()
    }
    
    // MARK: - User Authentication
    
    func login(username: String, password: String) {
        if let user = users.first(where: { $0.username == username && $0.password == password }) {
            currentUser = user
            isLoggedIn = true
        }
    }
    
    func signup(user: User) {
        users.append(user)
        currentUser = user
        isLoggedIn = true
        saveUsers()
    }
    
    // MARK: - Data Persistence
    
    private func loadUsers() {
        // Load users from storage or database
    }
    
    private func saveUsers() {
        // Save users to storage or database
    }
}

