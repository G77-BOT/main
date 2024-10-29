import Foundation
import SwiftData

@Model
final class Item: Identifiable {
    // MARK: - Properties
    
    let id: String
    var name: String
    var description: String
    var price: Double
    var quantity: Int
    var category: ItemCategory
    var condition: ItemCondition
    var images: [String]  // URLs to item images
    var location: Location?
    var tags: [String]
    var seller: User
    var status: ItemStatus
    var createdAt: Date
    var updatedAt: Date
    var rating: Double?
    var reviews: [Review]
    var sustainability: SustainabilityInfo
    var specifications: [String: String]
    var exchangePreferences: [String]
    var priceHistory: [PriceChange]
    var views: Int
    var favorites: Int
    var reportCount: Int
    var isVerified: Bool
    var isFeatured: Bool
    var lastPriceUpdate: Date
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        price: Double,
        quantity: Int,
        category: ItemCategory,
        condition: ItemCondition,
        images: [String],
        location: Location? = nil,
        tags: [String] = [],
        seller: User,
        status: ItemStatus = .available,
        rating: Double? = nil,
        specifications: [String: String] = [:],
        exchangePreferences: [String] = [],
        sustainability: SustainabilityInfo? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.quantity = quantity
        self.category = category
        self.condition = condition
        self.images = images
        self.location = location
        self.tags = tags
        self.seller = seller
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
        self.rating = rating
        self.reviews = []
        self.sustainability = sustainability ?? SustainabilityInfo()
        self.specifications = specifications
        self.exchangePreferences = exchangePreferences
        self.priceHistory = [PriceChange(price: price, date: Date())]
        self.views = 0
        self.favorites = 0
        self.reportCount = 0
        self.isVerified = false
        self.isFeatured = false
        self.lastPriceUpdate = Date()
    }
    
    // MARK: - Methods
    
    func updatePrice(_ newPrice: Double) {
        if newPrice != price {
            price = newPrice
            priceHistory.append(PriceChange(price: newPrice, date: Date()))
            lastPriceUpdate = Date()
            updatedAt = Date()
        }
    }
    
    func addReview(_ review: Review) {
        reviews.append(review)
        updateRating()
        updatedAt = Date()
    }
    
    func updateQuantity(_ newQuantity: Int) {
        quantity = newQuantity
        if quantity == 0 {
            status = .outOfStock
        } else if status == .outOfStock {
            status = .available
        }
        updatedAt = Date()
    }
    
    func incrementViews() {
        views += 1
    }
    
    func toggleFavorite(isAdding: Bool) {
        favorites += isAdding ? 1 : -1
        favorites = max(0, favorites)
    }
    
    func report() {
        reportCount += 1
        if reportCount >= 5 {
            status = .underReview
        }
    }
    
    func verify() {
        isVerified = true
        updatedAt = Date()
    }
    
    func feature() {
        isFeatured = true
        updatedAt = Date()
    }
    
    private func updateRating() {
        guard !reviews.isEmpty else {
            rating = nil
            return
        }
        
        rating = reviews.reduce(0.0) { $0 + $1.rating } / Double(reviews.count)
    }
    
    // MARK: - Computed Properties
    
    var isAvailable: Bool {
        return status == .available && quantity > 0
    }
    
    var averageRating: Double {
        return rating ?? 0.0
    }
    
    var formattedPrice: String {
        return String(format: "%.2f", price)
    }
    
    var daysSinceCreation: Int {
        return Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    var priceChangePercentage: Double? {
        guard priceHistory.count >= 2,
              let initialPrice = priceHistory.first?.price,
              initialPrice > 0 else {
            return nil
        }
        
        return ((price - initialPrice) / initialPrice) * 100
    }
}

// MARK: - Supporting Types

enum ItemCategory: String, Codable {
    case electronics
    case clothing
    case furniture
    case books
    case sports
    case outdoor
    case automotive
    case collectibles
    case homeAndGarden
    case other
}

enum ItemCondition: String, Codable {
    case new
    case likeNew
    case good
    case fair
    case poor
}

enum ItemStatus: String, Codable {
    case available
    case outOfStock
    case reserved
    case sold
    case underReview
    case suspended
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
    let address: String
    let city: String
    let country: String
    let postalCode: String
}

struct Review: Codable {
    let id: String
    let userId: String
    let rating: Double
    let comment: String
    let date: Date
    let helpful: Int
    let verified: Bool
}

struct SustainabilityInfo: Codable {
    var score: Int = 0
    var carbonFootprint: Double = 0.0
    var recycledMaterials: Bool = false
    var energyEfficiency: String = ""
    var certifications: [String] = []
    var sustainabilityFeatures: [String] = []
}

struct PriceChange: Codable {
    let price: Double
    let date: Date
}

// MARK: - Validation Extensions

extension Item {
    func validate() throws {
        // Basic validation
        guard !name.isEmpty else {
            throw ValidationError.invalidInput(field: "name", reason: "Name cannot be empty")
        }
        
        guard !description.isEmpty else {
            throw ValidationError.invalidInput(field: "description", reason: "Description cannot be empty")
        }
        
        guard price >= 0 else {
            throw ValidationError.invalidInput(field: "price", reason: "Price cannot be negative")
        }
        
        guard quantity >= 0 else {
            throw ValidationError.invalidInput(field: "quantity", reason: "Quantity cannot be negative")
        }
        
        // Image validation
        guard !images.isEmpty else {
            throw ValidationError.missingRequired(field: "images")
        }
        
        // Location validation
        if let location = location {
            guard location.latitude >= -90 && location.latitude <= 90 else {
                throw ValidationError.invalidInput(field: "latitude", reason: "Invalid latitude value")
            }
            
            guard location.longitude >= -180 && location.longitude <= 180 else {
                throw ValidationError.invalidInput(field: "longitude", reason: "Invalid longitude value")
            }
        }
        
        // Rating validation
        if let rating = rating {
            guard rating >= 0 && rating <= 5 else {
                throw ValidationError.invalidInput(field: "rating", reason: "Rating must be between 0 and 5")
            }
        }
    }
}

// MARK: - Searchable Extension

extension Item {
    var searchableContent: String {
        [
            name,
            description,
            category.rawValue,
            condition.rawValue,
            tags.joined(separator: " "),
            specifications.values.joined(separator: " ")
        ].joined(separator: " ").lowercased()
    }
}

// MARK: - Analytics Extension

extension Item {
    var analyticsData: [String: Any] {
        [
            "item_id": id,
            "name": name,
            "category": category.rawValue,
            "price": price,
            "condition": condition.rawValue,
            "status": status.rawValue,
            "seller_id": seller.id,
            "views": views,
            "favorites": favorites,
            "rating": rating ?? 0,
            "days_listed": daysSinceCreation,
            "is_verified": isVerified,
            "is_featured": isFeatured,
            "sustainability_score": sustainability.score
        ]
    }
}