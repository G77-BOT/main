//
//  AsyncAlgorithms.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import Foundation

class EcommerceApp {
    private let adCache = NSCache<NSString, NSArray>()
    
    // Personalized Ads
    func showPersonalizedAds(forUser user: CommerceUser) async throws -> [Ad] {
        if let cachedAds = adCache.object(forKey: NSString(string: user.id)) as? [Ad] {
            return cachedAds
        } else {
            let ads = try await fetchPersonalizedAds()
            adCache.setObject(NSArray(array: ads), forKey: NSString(string: user.id))
            return ads
        }
    }
    
    private func fetchPersonalizedAds() async throws -> [Ad] {
        try await Task.sleep(nanoseconds: 2_000_000_000) // Simulating network delay
        
        let ads = [
            Ad(title: "Special Offer", description: "Get 20% off on selected products!", imageURL: "https://example.com/ads/special_offer.png"),
            Ad(title: "New Arrivals", description: "Check out the latest products in our store.", imageURL: "https://example.com/ads/new_arrivals.png")
        ]
        
        return ads
    }
    
    // Location Tracking
    func trackLocation(forUser user: CommerceUser) async throws -> Location {
        return try await fetchLocation()
    }
    
    private func fetchLocation() async throws -> Location {
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulating network delay
        
        let location = Location(latitude: 37.7749, longitude: -122.4194)
        return location
    }
    
    // Search History
    func fetchSearchHistory(forUser user: CommerceUser) async throws -> [SearchQuery] {
        return try await fetchUserSearchHistory()
    }
    
    private func fetchUserSearchHistory() async throws -> [SearchQuery] {
        try await Task.sleep(nanoseconds: 2_000_000_000) // Simulating network delay
        
        let searchQueries = [
            SearchQuery(query: "iPhone", timestamp: Date()),
            SearchQuery(query: "Laptop", timestamp: Date().addingTimeInterval(-86400)) // 24 hours ago
        ]
        
        return searchQueries
    }
}

// Models
struct CommerceUser {
    let id: String
}

struct Ad {
    let title: String
    let description: String
    let imageURL: String
}

struct Location {
    let latitude: Double
    let longitude: Double
}

struct SearchQuery {
    let query: String
    let timestamp: Date
}

// Usage
func testEcommerceApp() async {
    let app = EcommerceApp()
    let user = CommerceUser(id: "123")
    
    do {
        let personalizedAds = try await app.showPersonalizedAds(forUser: user)
        print("Personalized Ads: \(personalizedAds)")
        
        let location = try await app.trackLocation(forUser: user)
        print("User's Location: \(location)")
        
        let searchHistory = try await app.fetchSearchHistory(forUser: user)
        print("Search History: \(searchHistory)")
    } catch {
        print("Error: \(error)")
    }
}
