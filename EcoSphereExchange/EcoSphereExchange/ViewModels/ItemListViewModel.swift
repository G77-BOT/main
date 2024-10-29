import Foundation
import Combine

@MainActor
final class ItemListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var items: [Item] = []
    @Published var filteredItems: [Item] = []
    @Published var selectedCategory: ItemCategory?
    @Published var searchText = ""
    @Published var sortOption: SortOption = .recommended
    @Published var filterOptions = FilterOptions()
    @Published var isLoading = false
    @Published var error: Error?
    @Published var loadingState = LoadingState.idle
    
    // MARK: - Private Properties
    
    private let analyticsManager = AnalyticsManager.shared
    private let securityProvider = SecurityProvider.shared
    private var cancellables = Set<AnyCancellable>()
    private let itemsPerPage = 20
    private var currentPage = 1
    private var hasMorePages = true
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    func loadItems() async {
        guard !isLoading else { return }
        
        do {
            loadingState = .loading
            isLoading = true
            
            let newItems = try await fetchItems()
            items.append(contentsOf: newItems)
            applyFiltersAndSort()
            
            loadingState = .loaded
            trackLoadSuccess(itemCount: newItems.count)
            
        } catch {
            self.error = error
            loadingState = .error(error)
            trackLoadError(error)
        }
        
        isLoading = false
    }
    
    func refreshItems() async {
        items = []
        currentPage = 1
        hasMorePages = true
        await loadItems()
    }
    
    func loadMoreIfNeeded(currentItem item: Item) async {
        guard let itemIndex = filteredItems.firstIndex(where: { $0.id == item.id }),
              itemIndex == filteredItems.count - 5,
              !isLoading,
              hasMorePages else {
            return
        }
        
        currentPage += 1
        await loadItems()
    }
    
    func filterItems(by category: ItemCategory?) {
        selectedCategory = category
        applyFiltersAndSort()
        trackFilterApplication()
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
        applyFiltersAndSort()
        trackSearch()
    }
    
    func updateSortOption(_ option: SortOption) {
        sortOption = option
        applyFiltersAndSort()
        trackSortApplication()
    }
    
    func updateFilterOptions(_ options: FilterOptions) {
        filterOptions = options
        applyFiltersAndSort()
        trackFilterApplication()
    }
    
    func toggleFavorite(for item: Item) async {
        do {
            try await ItemService.shared.toggleFavorite(item)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
                applyFiltersAndSort()
            }
            trackFavoriteToggle(item: item)
        } catch {
            self.error = error
            trackError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Combine search text, category, and sort option changes
        Publishers.CombineLatest3($searchText, $selectedCategory, $sortOption)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
    }
    
    private func fetchItems() async throws -> [Item] {
        return try await ItemService.shared.fetchItems(
            page: currentPage,
            itemsPerPage: itemsPerPage,
            category: selectedCategory,
            filters: filterOptions
        )
    }
    
    private func applyFiltersAndSort() {
        var filtered = items
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.searchableContent.contains(searchText.lowercased())
            }
        }
        
        // Apply price range filter
        filtered = filtered.filter { item in
            let price = item.price
            return price >= filterOptions.minPrice && price <= filterOptions.maxPrice
        }
        
        // Apply condition filter
        if !filterOptions.conditions.isEmpty {
            filtered = filtered.filter { filterOptions.conditions.contains($0.condition) }
        }
        
        // Apply availability filter
        if filterOptions.onlyAvailable {
            filtered = filtered.filter { $0.isAvailable }
        }
        
        // Apply verified seller filter
        if filterOptions.onlyVerifiedSellers {
            filtered = filtered.filter { $0.seller.isVerified }
        }
        
        // Apply shipping filter
        if filterOptions.freeShippingOnly {
            filtered = filtered.filter { $0.shippingCost == 0 }
        }
        
        // Apply sorting
        filtered.sort { lhs, rhs in
            switch sortOption {
            case .recommended:
                return lhs.rating ?? 0 > rhs.rating ?? 0
            case .priceAscending:
                return lhs.price < rhs.price
            case .priceDescending:
                return lhs.price > rhs.price
            case .newest:
                return lhs.createdAt > rhs.createdAt
            case .mostPopular:
                return lhs.views > rhs.views
            case .bestRated:
                return (lhs.rating ?? 0) > (rhs.rating ?? 0)
            }
        }
        
        filteredItems = filtered
    }
    
    // MARK: - Analytics
    
    private func trackLoadSuccess(itemCount: Int) {
        analyticsManager.trackEvent(.itemListLoaded(
            count: itemCount,
            page: currentPage,
            category: selectedCategory?.rawValue,
            searchQuery: searchText,
            sortOption: sortOption.rawValue,
            filterOptions: filterOptions
        ))
    }
    
    private func trackLoadError(_ error: Error) {
        analyticsManager.trackError(error)
    }
    
    private func trackSearch() {
        guard !searchText.isEmpty else { return }
        analyticsManager.trackEvent(.search(
            query: searchText,
            resultCount: filteredItems.count,
            duration: 0
        ))
    }
    
    private func trackFilterApplication() {
        analyticsManager.trackEvent(.filterApplied(
            category: selectedCategory?.rawValue,
            options: filterOptions,
            resultCount: filteredItems.count
        ))
    }
    
    private func trackSortApplication() {
        analyticsManager.trackEvent(.sortApplied(
            option: sortOption.rawValue,
            resultCount: filteredItems.count
        ))
    }
    
    private func trackFavoriteToggle(item: Item) {
        analyticsManager.trackEvent(.itemFavorited(
            itemId: item.id,
            isFavorited: item.favorites > 0
        ))
    }
    
    private func trackError(_ error: Error) {
        analyticsManager.trackError(error)
    }
}

// MARK: - Supporting Types

enum SortOption: String, CaseIterable {
    case recommended = "Recommended"
    case priceAscending = "Price: Low to High"
    case priceDescending = "Price: High to Low"
    case newest = "Newest First"
    case mostPopular = "Most Popular"
    case bestRated = "Best Rated"
}

struct FilterOptions {
    var minPrice: Double = 0
    var maxPrice: Double = Double.infinity
    var conditions: Set<ItemCondition> = []
    var onlyAvailable: Bool = false
    var onlyVerifiedSellers: Bool = false
    var freeShippingOnly: Bool = false
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