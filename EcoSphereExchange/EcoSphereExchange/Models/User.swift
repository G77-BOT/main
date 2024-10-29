import Foundation
import SwiftData

@Model
final class User: Identifiable {
    // MARK: - Properties
    
    let id: String
    var username: String
    var email: String
    var phoneNumber: String?
    var profileImage: String?
    var biography: String?
    var location: Location?
    var joinDate: Date
    var lastLoginDate: Date?
    var reputation: Double
    var verificationStatus: VerificationStatus
    var roles: [UserRole]
    var preferences: UserPreferences
    var stats: UserStats
    var wallet: Wallet
    var settings: UserSettings
    var notification: NotificationPreferences
    var security: SecuritySettings
    var sustainabilityScore: Int
    var badges: [Badge]
    var following: [String]  // User IDs
    var followers: [String]  // User IDs
    var blockedUsers: [String]  // User IDs
    var listedItems: [Item]
    var purchaseHistory: [Transaction]
    var favoriteItems: [String]  // Item IDs
    var reviews: [Review]
    var reportCount: Int
    var isActive: Bool
    var isBanned: Bool
    var banReason: String?
    var lastActivity: Date
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        username: String,
        email: String,
        phoneNumber: String? = nil,
        profileImage: String? = nil,
        biography: String? = nil,
        location: Location? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.phoneNumber = phoneNumber
        self.profileImage = profileImage
        self.biography = biography
        self.location = location
        self.joinDate = Date()
        self.lastLoginDate = Date()
        self.reputation = 0.0
        self.verificationStatus = .unverified
        self.roles = [.user]
        self.preferences = UserPreferences()
        self.stats = UserStats()
        self.wallet = Wallet()
        self.settings = UserSettings()
        self.notification = NotificationPreferences()
        self.security = SecuritySettings()
        self.sustainabilityScore = 0
        self.badges = []
        self.following = []
        self.followers = []
        self.blockedUsers = []
        self.listedItems = []
        self.purchaseHistory = []
        self.favoriteItems = []
        self.reviews = []
        self.reportCount = 0
        self.isActive = true
        self.isBanned = false
        self.banReason = nil
        self.lastActivity = Date()
    }
    
    // MARK: - Methods
    
    func updateProfile(
        username: String? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        profileImage: String? = nil,
        biography: String? = nil,
        location: Location? = nil
    ) {
        if let username = username { self.username = username }
        if let email = email { self.email = email }
        if let phoneNumber = phoneNumber { self.phoneNumber = phoneNumber }
        if let profileImage = profileImage { self.profileImage = profileImage }
        if let biography = biography { self.biography = biography }
        if let location = location { self.location = location }
        updateLastActivity()
    }
    
    func recordLogin() {
        lastLoginDate = Date()
        updateLastActivity()
    }
    
    func updateReputation(change: Double) {
        reputation = min(max(reputation + change, 0), 5)
        updateLastActivity()
    }
    
    func verify(_ status: VerificationStatus) {
        verificationStatus = status
        updateLastActivity()
    }
    
    func addRole(_ role: UserRole) {
        if !roles.contains(role) {
            roles.append(role)
        }
        updateLastActivity()
    }
    
    func removeRole(_ role: UserRole) {
        roles.removeAll { $0 == role }
        updateLastActivity()
    }
    
    func follow(_ userId: String) {
        if !following.contains(userId) {
            following.append(userId)
        }
        updateLastActivity()
    }
    
    func unfollow(_ userId: String) {
        following.removeAll { $0 == userId }
        updateLastActivity()
    }
    
    func block(_ userId: String) {
        if !blockedUsers.contains(userId) {
            blockedUsers.append(userId)
            // Remove from following/followers if needed
            following.removeAll { $0 == userId }
            followers.removeAll { $0 == userId }
        }
        updateLastActivity()
    }
    
    func unblock(_ userId: String) {
        blockedUsers.removeAll { $0 == userId }
        updateLastActivity()
    }
    
    func listItem(_ item: Item) {
        listedItems.append(item)
        stats.itemsListed += 1
        updateLastActivity()
    }
    
    func recordPurchase(_ transaction: Transaction) {
        purchaseHistory.append(transaction)
        stats.itemsPurchased += 1
        updateSustainabilityScore()
        updateLastActivity()
    }
    
    func favoriteItem(_ itemId: String) {
        if !favoriteItems.contains(itemId) {
            favoriteItems.append(itemId)
        }
        updateLastActivity()
    }
    
    func unfavoriteItem(_ itemId: String) {
        favoriteItems.removeAll { $0 == itemId }
        updateLastActivity()
    }
    
    func addReview(_ review: Review) {
        reviews.append(review)
        updateReputation(change: (review.rating - 2.5) / 5.0)
        updateLastActivity()
    }
    
    func report() {
        reportCount += 1
        if reportCount >= 5 {
            isActive = false
        }
        updateLastActivity()
    }
    
    func ban(_ reason: String) {
        isBanned = true
        banReason = reason
        isActive = false
        updateLastActivity()
    }
    
    func unban() {
        isBanned = false
        banReason = nil
        isActive = true
        updateLastActivity()
    }
    
    private func updateSustainabilityScore() {
        // Calculate based on purchase history, listing behavior, etc.
        let baseScore = purchaseHistory.reduce(0) { score, transaction in
            score + (transaction.item.sustainability.score * 2)
        }
        
        sustainabilityScore = min(max(baseScore, 0), 100)
        
        // Update badges if needed
        updateSustainabilityBadges()
    }
    
    private func updateSustainabilityBadges() {
        if sustainabilityScore >= 80 && !badges.contains(where: { $0.type == .sustainabilityChampion }) {
            badges.append(Badge(type: .sustainabilityChampion, date: Date()))
        }
    }
    
    private func updateLastActivity() {
        lastActivity = Date()
    }
    
    // MARK: - Computed Properties
    
    var isVerified: Bool {
        return verificationStatus == .verified
    }
    
    var completionRate: Double {
        guard stats.totalTransactions > 0 else { return 0 }
        return Double(stats.successfulTransactions) / Double(stats.totalTransactions) * 100
    }
    
    var responseRate: Double {
        guard stats.totalMessages > 0 else { return 0 }
        return Double(stats.respondedMessages) / Double(stats.totalMessages) * 100
    }
}

// MARK: - Supporting Types

enum VerificationStatus: String, Codable {
    case unverified
    case pending
    case verified
    case rejected
}

enum UserRole: String, Codable {
    case user
    case seller
    case moderator
    case admin
}

struct UserPreferences: Codable {
    var currency: String = "USD"
    var language: String = "en"
    var theme: String = "light"
    var receivePromotions: Bool = true
    var receiveNewsletter: Bool = true
    var showOnlineStatus: Bool = true
    var searchRadius: Double = 50.0  // kilometers
}

struct UserStats: Codable {
    var itemsListed: Int = 0
    var itemsPurchased: Int = 0
    var totalTransactions: Int = 0
    var successfulTransactions: Int = 0
    var canceledTransactions: Int = 0
    var totalMessages: Int = 0
    var respondedMessages: Int = 0
    var averageResponseTime: TimeInterval = 0
}

struct Wallet: Codable {
    var balance: Double = 0.0
    var currency: String = "USD"
    var transactions: [WalletTransaction] = []
    var paymentMethods: [PaymentMethod] = []
}

struct UserSettings: Codable {
    var visibility: VisibilitySettings = VisibilitySettings()
    var privacy: PrivacySettings = PrivacySettings()
    var communication: CommunicationSettings = CommunicationSettings()
}

struct VisibilitySettings: Codable {
    var profileVisibility: Visibility = .public
    var contactInfoVisibility: Visibility = .private
    var activityVisibility: Visibility = .followers
}

struct PrivacySettings: Codable {
    var allowMessagesFrom: MessagePrivacy = .all
    var showOnlineStatus: Bool = true
    var showLastSeen: Bool = true
}

struct CommunicationSettings: Codable {
    var emailFrequency: EmailFrequency = .daily
    var pushNotifications: Bool = true
    var smsNotifications: Bool = false
}

struct NotificationPreferences: Codable {
    var messages: Bool = true
    var transactions: Bool = true
    var updates: Bool = true
    var marketing: Bool = false
    var newsletter: Bool = false
}

struct SecuritySettings: Codable {
    var twoFactorEnabled: Bool = false
    var loginNotifications: Bool = true
    var trustedDevices: [String] = []
    var lastPasswordChange: Date?
    var securityQuestions: [SecurityQuestion] = []
}

struct SecurityQuestion: Codable {
    let question: String
    let answer: String
}

struct Badge: Codable {
    let type: BadgeType
    let date: Date
    var level: Int = 1
}

enum BadgeType: String, Codable {
    case newMember
    case trustedSeller
    case sustainabilityChampion
    case topRated
    case quickResponder
    case powerSeller
}

enum Visibility: String, Codable {
    case `public`
    case private
    case followers
}

enum MessagePrivacy: String, Codable {
    case all
    case followers
    case none
}

enum EmailFrequency: String, Codable {
    case never
    case daily
    case weekly
    case monthly
}

// MARK: - Validation Extension

extension User {
    func validate() throws {
        // Username validation
        guard username.count >= 3 && username.count <= 30 else {
            throw ValidationError.invalidInput(field: "username", reason: "Username must be between 3 and 30 characters")
        }
        
        // Email validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard email.range(of: emailRegex, options: .regularExpression) != nil else {
            throw ValidationError.invalidFormat(field: "email", expectedFormat: "valid email address")
        }
        
        // Phone number validation (if provided)
        if let phone = phoneNumber {
            let phoneRegex = "^\\+?[1-9]\\d{1,14}$"
            guard phone.range(of: phoneRegex, options: .regularExpression) != nil else {
                throw ValidationError.invalidFormat(field: "phone", expectedFormat: "E.164 format")
            }
        }
        
        // Biography validation
        if let bio = biography {
            guard bio.count <= 500 else {
                throw ValidationError.invalidInput(field: "biography", reason: "Biography must not exceed 500 characters")
            }
        }
    }
}