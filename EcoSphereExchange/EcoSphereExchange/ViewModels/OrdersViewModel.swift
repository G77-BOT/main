import Foundation
import Combine

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published private(set) var orders: [Order] = []
    @Published private(set) var isLoading = false
    @Published var showingError = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private var currentPage = 1
    private let itemsPerPage = 20
    private(set) var hasMoreOrders = true
    
    init() {
        Task {
            await fetchOrders()
        }
    }
    
    func fetchOrders(status: OrderStatus? = nil) async {
        isLoading = true
        currentPage = 1
        hasMoreOrders = true
        
        do {
            let response: OrdersResponse = try await apiService.get(
                endpoint: .orders(status: status?.rawValue)
            )
            orders = response.orders
            hasMoreOrders = response.hasMore
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func loadMoreOrders() async {
        guard hasMoreOrders && !isLoading else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let response: OrdersResponse = try await apiService.get(
                endpoint: .orders(
                    page: currentPage,
                    limit: itemsPerPage
                )
            )
            orders.append(contentsOf: response.orders)
            hasMoreOrders = response.hasMore
            isLoading = false
        } catch {
            handleError(error)
            currentPage -= 1
        }
    }
    
    func cancelOrder(_ order: Order) async {
        isLoading = true
        do {
            let updatedOrder: Order = try await apiService.post(
                endpoint: .cancelOrder(id: order.id),
                body: EmptyRequest()
            )
            if let index = orders.firstIndex(where: { $0.id == order.id }) {
                orders[index] = updatedOrder
            }
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func trackOrder(_ order: Order) async -> OrderTracking? {
        isLoading = true
        do {
            let tracking: OrderTracking = try await apiService.get(
                endpoint: .orderTracking(id: order.id)
            )
            isLoading = false
            return tracking
        } catch {
            handleError(error)
            return nil
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

// Response Models
struct OrdersResponse: Codable {
    let orders: [Order]
    let totalCount: Int
    let hasMore: Bool
}

struct OrderTracking: Codable {
    let orderId: UUID
    let trackingNumber: String
    let carrier: String
    let status: String
    let estimatedDelivery: Date?
    let updates: [TrackingUpdate]
}

struct TrackingUpdate: Codable {
    let status: String
    let location: String
    let timestamp: Date
    let description: String
}

struct EmptyRequest: Codable {}