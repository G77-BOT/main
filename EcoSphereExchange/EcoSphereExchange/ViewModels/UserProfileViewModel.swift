import Foundation
import Combine
import SwiftData

@MainActor
final class UserProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var user: User?
    @Published var listedItems: [Item] = []
    @Published var purchaseHistory: [Order] = []
    @Published var favoriteItems: [Item] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var editMode = false
    @Published var profileImage: Data?
    @Published var updatedUsername = ""
    @Published var updatedEmail = ""
    @Published var updatedBio = ""
    @Published var updatedLocation: Location?
    @Published var loadingState = LoadingState.idle
    
    // MARK: - Private Properties
    
    private let userSession = UserSession.shared
    private let analyticsManager = AnalyticsManager.shared
    private let securityProvider = SecurityProvider.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        loadUserProfile()
    }
    
    // MARK: - Public Methods
    
    func loadUserProfile() {
        guard !isLoading else { return }
        
        Task {
            do {
                loadingState = .loading
                isLoading = true
                
                self.user = try await UserService.shared.fetchUserProfile()
                await loadUserData()
                
                loadingState = .loaded
                trackProfileLoad()
                
            } catch {
                self.error = error
                loadingState = .error(error)
                trackError(error)
            }
            
            isLoading = false
        }
    }
    
    func updateProfile() async throws {
        guard var updatedUser = user else {
            throw ProfileError.userNotFound
        }
        
        do {
            isLoading = true
            
            // Validate inputs
            try validateProfileInputs()
            
            // Update user properties
            updatedUser.username = updatedUsername
            updatedUser.email = updatedEmail
            updatedUser.biography = updatedBio
            updatedUser.location = updatedLocation
            
            // Upload profile image if changed
            if let imageData = profileImage {
                let imageURL = try await uploadProfileImage(imageData)
                updatedUser.profileImage = imageURL
            }
            
            // Update user profile
            try await UserService.shared.updateUserProfile(updatedUser)
            
            self.user = updatedUser
            editMode = false
            
            trackProfileUpdate()
            
        } catch {
            self.error = error
            trackError(error)
            throw error
        }
        
        isLoading = false
    }
    
    func toggleFavorite(item: Item) async {
        do {
            try await ItemService.shared.toggleFavorite(item)
            
            if favoriteItems.contains(where: { $0.id == item.id }) {
                favoriteItems.removeAll { $0.id == item.id }
            } else {
                favoriteItems.append(item)
            }
            
            trackFavoriteToggle(item: item)
            
        } catch {
            self.error = error
            trackError(error)
        }
    }
    
    func deleteItem(_ item: Item) async throws {
        do {
            isLoading = true
            
            try await ItemService.shared.deleteItem(item)
            listedItems.removeAll { $0.id == item.id }
            
            trackItemDeletion(item: item)
            
        } catch {
            self.error = error
            trackError(error)
            throw error
        }
        
        isLoading = false
    }
    
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async {
        do {
            isLoading = true
            
            guard var updatedUser = user else {
                throw ProfileError.userNotFound
            }
            
            updatedUser.notification = preferences
            try await UserService.shared.updateUserProfile(updatedUser)
            
            self.user = updatedUser
            trackPreferencesUpdate()
            
        } catch {
            self.error = error
            trackError(error)
        }
        
        isLoading = false
    }
    
    func updatePrivacySettings(_ settings: PrivacySettings) async {
        do {
            isLoading = true
            
            guard var updatedUser = user else {
                throw ProfileError.userNotFound
            }
            
            updatedUser.settings.privacy = settings
            try await UserService.shared.updateUserProfile(updatedUser)
            
            self.user = updatedUser
            trackPrivacyUpdate()
            
        } catch {
            self.error = error
            trackError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor user session changes
        userSession.$user
            .sink { [weak self] user in
                self?.user = user
                if user != nil {
                    self?.loadUserProfile()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadUserData() async {
        guard let userId = user?.id else { return }
        
        async let items = ItemService.shared.fetchUserItems(userId: userId)
        async let orders = OrderService.shared.fetchUserOrders(userId: userId)
        async let favorites = ItemService.shared.fetchFavoriteItems(userId: userId)
        
        do {
            let (fetchedItems, fetchedOrders, fetchedFavorites) = await (
                try items,
                try orders,
                try favorites
            )
            
            self.listedItems = fetchedItems
            self.purchaseHistory = fetchedOrders
            self.favoriteItems = fetchedFavorites
            
        } catch {
            self.error = error
            trackError(error)
        }
    }
    
    private func validateProfileInputs() throws {
        // Validate username
        guard updatedUsername.count >= 3 && updatedUsername.count <= 30 else {
            throw ValidationError.invalidInput(
                field: "username",
                reason: "Username must be between 3 and 30 characters"
            )
        }
        
        // Validate email
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard updatedEmail.range(of: emailRegex, options: .regularExpression) != nil else {
            throw ValidationError.invalidFormat(
                field: "email",
                expectedFormat: "valid email address"
            )
        }
        
        // Validate biography
        if !updatedBio.isEmpty {
            guard updatedBio.count <= 500 else {
                throw ValidationError.invalidInput(
                    field: "biography",
                    reason: "Biography must not exceed 500 characters"
                )
            }
        }
    }
    
    private func uploadProfileImage(_ imageData: Data) async throws -> String {
        let result = try await APIService.shared.uploadFile(
            endpoint: .uploadProfileImage,
            fileURL: try saveImageTemporarily(imageData),
            mimeType: "image/jpeg"
        )
        return result.url
    }
    
    private func saveImageTemporarily(_ imageData: Data) throws -> URL {
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        
        try imageData.write(to: temporaryURL)
        return temporaryURL
    }
    
    // MARK: - Analytics
    
    private func trackProfileLoad() {
        analyticsManager.trackEvent(.profileViewed(
            userId: user?.id ?? "",
            isOwnProfile: true
        ))
    }
    
    private func trackProfileUpdate() {
        analyticsManager.trackEvent(.profileUpdated(
            userId: user?.id ?? "",
            updatedFields: ["username", "email", "bio", "location", "image"]
        ))
    }
    
    private func trackFavoriteToggle(item: Item) {
        analyticsManager.trackEvent(.itemFavorited(
            itemId: item.id,
            isFavorited: favoriteItems.contains(where: { $0.id == item.id })
        ))
    }
    
    private func trackItemDeletion(item: Item) {
        analyticsManager.trackEvent(.itemDeleted(
            itemId: item.id,
            reason: "user_initiated"
        ))
    }
    
    private func trackPreferencesUpdate() {
        analyticsManager.trackEvent(.preferencesUpdated(
            userId: user?.id ?? "",
            type: "notifications"
        ))
    }
    
    private func trackPrivacyUpdate() {
        analyticsManager.trackEvent(.preferencesUpdated(
            userId: user?.id ?? "",
            type: "privacy"
        ))
    }
    
    private func trackError(_ error: Error) {
        analyticsManager.trackError(error)
    }
}

// MARK: - Supporting Types

enum ProfileError: LocalizedError {
    case userNotFound
    case updateFailed
    case invalidImage
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User profile not found"
        case .updateFailed:
            return "Failed to update profile"
        case .invalidImage:
            return "Invalid profile image"
        case .uploadFailed:
            return "Failed to upload profile image"
        }
    }
}

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(Error)
    
    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.loaded, .loaded):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}