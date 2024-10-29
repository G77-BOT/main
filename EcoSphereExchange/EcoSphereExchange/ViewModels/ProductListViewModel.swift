import Foundation
import Combine

@MainActor
final class ProductListViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published var showingError = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private var currentPage = 1
    private let itemsPerPage = 20
    private(set) var hasMoreProducts = true
    
    init() {
        Task {
            await fetchProducts()
        }
    }
    
    func fetchProducts(category: Category? = nil, sortBy: SortOption = .recommended) async {
        isLoading = true
        currentPage = 1
        hasMoreProducts = true
        
        do {
            let response: ProductsResponse = try await apiService.get(
                endpoint: .products(
                    page: currentPage,
                    limit: itemsPerPage,
                    category: category?.rawValue,
                    sortBy: sortBy.rawValue
                )
            )
            products = response.products
            hasMoreProducts = response.hasMore
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func loadMoreProducts() async {
        guard hasMoreProducts && !isLoading else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let response: ProductsResponse = try await apiService.get(
                endpoint: .products(
                    page: currentPage,
                    limit: itemsPerPage
                )
            )
            products.append(contentsOf: response.products)
            hasMoreProducts = response.hasMore
            isLoading = false
        } catch {
            handleError(error)
            currentPage -= 1
        }
    }
    
    private func handleError(_ error: Error) {
        isLoading = false
        if let apiError = error as? APIError {
            errorMessage = apiError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showingError = true
    }
}

extension SortOption {
    var rawValue: String {
        switch self {
        case .recommended:
            return "recommended"
        case .priceLowToHigh:
            return "price_asc"
        case .priceHighToLow:
            return "price_desc"
        case .newest:
            return "newest"
        case .bestRated:
            return "rating"
        }
    }
}

struct ProductsResponse: Codable {
    let products: [Product]
    let totalCount: Int
    let hasMore: Bool
}