import Foundation
import Combine

@MainActor
final class WalletViewModel: ObservableObject {
    @Published private(set) var wallet: Wallet
    @Published private(set) var isLoading = false
    @Published var showingError = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.wallet = Wallet()
        Task {
            await refreshWallet()
        }
    }
    
    func refreshWallet() async {
        isLoading = true
        do {
            let updatedWallet: Wallet = try await apiService.get(endpoint: .wallet())
            wallet = updatedWallet
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func addFunds(amount: Double, paymentMethod: PaymentMethod) async {
        isLoading = true
        do {
            let request = AddFundsRequest(amount: amount, paymentMethodId: paymentMethod.id)
            let response: Transaction = try await apiService.post(endpoint: .addFunds(), body: request)
            await refreshWallet()
        } catch {
            handleError(error)
        }
    }
    
    func withdrawFunds(amount: Double, paymentMethod: PaymentMethod) async {
        isLoading = true
        do {
            let request = WithdrawRequest(amount: amount, paymentMethodId: paymentMethod.id)
            let response: Transaction = try await apiService.post(endpoint: .withdrawFunds(), body: request)
            await refreshWallet()
        } catch {
            handleError(error)
        }
    }
    
    func addPaymentMethod(_ method: PaymentMethod) async {
        isLoading = true
        do {
            let response: PaymentMethod = try await apiService.post(endpoint: .addPaymentMethod(), body: method)
            wallet.addPaymentMethod(response)
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func removePaymentMethod(id: UUID) {
        Task {
            isLoading = true
            do {
                try await apiService.delete(endpoint: .removePaymentMethod(id: id))
                wallet.removePaymentMethod(id: id)
                isLoading = false
            } catch {
                handleError(error)
            }
        }
    }
    
    func fetchTransactionHistory(page: Int = 1, limit: Int = 20) async {
        isLoading = true
        do {
            let response: TransactionsResponse = try await apiService.get(
                endpoint: .walletTransactions(page: page, limit: limit)
            )
            // Update transactions in wallet
            wallet.transactions.append(contentsOf: response.transactions)
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        isLoading = false
        if let apiError = error as? APIError {
            errorMessage = apiError.errorDescription
        } else if let walletError = error as? WalletError {
            errorMessage = walletError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showingError = true
    }
}

// Request/Response Models
struct AddFundsRequest: Codable {
    let amount: Double
    let paymentMethodId: UUID
}

struct WithdrawRequest: Codable {
    let amount: Double
    let paymentMethodId: UUID
}

struct TransactionsResponse: Codable {
    let transactions: [Transaction]
    let totalCount: Int
    let hasMore: Bool
}