import Foundation
import SwiftData

@Model
final class Product: Identifiable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var price: Double
    var imageURL: String?
    var category: Category
    var tags: [String]
    var stock: Int
    var rating: Double
    var reviews: [Review]
    var seller: User
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        price: Double,
        imageURL: String? = nil,
        category: Category,
        tags: [String] = [],
        stock: Int = 0,
        rating: Double = 0.0,
        reviews: [Review] = [],
        seller: User,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.imageURL = imageURL
        self.category = category
        self.tags = tags
        self.stock = stock
        self.rating = rating
        self.reviews = reviews
        self.seller = seller
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func updateStock(_ quantity: Int) {
        stock = max(0, stock + quantity)
        updatedAt = Date()
    }
    
    func addReview(_ review: Review) {
        reviews.append(review)
        updateRating()
        updatedAt = Date()
    }
    
    private func updateRating() {
        rating = reviews.isEmpty ? 0 : reviews.reduce(0) { $0 + $1.rating } / Double(reviews.count)
    }
}

enum Category: String, Codable {
    case electronics
    case clothing
    case books
    case homeAndGarden
    case sports
    case toys
    case food
    case beauty
    case health
    case automotive
    case other
}

struct Review: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let rating: Double
    let comment: String
    let createdAt: Date
    
    init(id: UUID = UUID(), userId: UUID, rating: Double, comment: String, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.rating = max(0, min(5, rating))
        self.comment = comment
        self.createdAt = createdAt
    }
}
