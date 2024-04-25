//
//  EcoSphereExchangeApp.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-03-24.
//

import SwiftUI
import SwiftData

@main
struct EcoSphereExchangeApp: App {
    @StateObject var userSession = UserSession() // Create an instance of UserSession
    @StateObject var cart = Cart() // Create an instance of Cart

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession) // Inject UserSession
                .environmentObject(cart) // Inject Cart
        }
    }
}

