import SwiftUI

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel()
    @State private var showingAddFundsSheet = false
    @State private var showingWithdrawSheet = false
    @State private var showingPaymentMethodSheet = false
    @State private var selectedTransaction: Transaction?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance Card
                    BalanceCard(
                        balance: viewModel.wallet.balance,
                        currency: viewModel.wallet.currency,
                        onAddFunds: { showingAddFundsSheet = true },
                        onWithdraw: { showingWithdrawSheet = true }
                    )
                    
                    // Payment Methods
                    PaymentMethodsSection(
                        paymentMethods: viewModel.wallet.paymentMethods,
                        onAddMethod: { showingPaymentMethodSheet = true },
                        onDeleteMethod: viewModel.removePaymentMethod
                    )
                    
                    // Recent Transactions
                    TransactionsSection(
                        transactions: viewModel.wallet.transactions,
                        onSelect: { transaction in
                            selectedTransaction = transaction
                        }
                    )
                }
                .padding()
            }
            .navigationTitle("Wallet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Refresh wallet data
                        Task {
                            await viewModel.refreshWallet()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingAddFundsSheet) {
                AddFundsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingWithdrawSheet) {
                WithdrawFundsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingPaymentMethodSheet) {
                AddPaymentMethodView(viewModel: viewModel)
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailView(transaction: transaction)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

struct BalanceCard: View {
    let balance: Double
    let currency: String
    let onAddFunds: () -> Void
    let onWithdraw: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Available Balance")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\(currency) \(String(format: "%.2f", balance))")
                .font(.system(size: 36, weight: .bold))
            
            HStack(spacing: 20) {
                Button(action: onAddFunds) {
                    Label("Add Funds", systemImage: "plus.circle.fill")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: onWithdraw) {
                    Label("Withdraw", systemImage: "arrow.down.circle.fill")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

struct PaymentMethodsSection: View {
    let paymentMethods: [PaymentMethod]
    let onAddMethod: () -> Void
    let onDeleteMethod: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Payment Methods")
                    .font(.headline)
                Spacer()
                Button(action: onAddMethod) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if paymentMethods.isEmpty {
                Text("No payment methods added")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(paymentMethods, id: \.id) { method in
                    PaymentMethodCard(method: method) {
                        onDeleteMethod(method.id)
                    }
                }
            }
        }
    }
}

struct PaymentMethodCard: View {
    let method: PaymentMethod
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: method.type.iconName)
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(method.provider)
                    .font(.headline)
                if let lastFour = method.lastFourDigits {
                    Text("••••\(lastFour)")
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if method.isDefault {
                Text("Default")
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct TransactionsSection: View {
    let transactions: [Transaction]
    let onSelect: (Transaction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Transactions")
                .font(.headline)
            
            if transactions.isEmpty {
                Text("No transactions yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(transactions, id: \.id) { transaction in
                    TransactionCard(transaction: transaction)
                        .onTapGesture {
                            onSelect(transaction)
                        }
                }
            }
        }
    }
}

struct TransactionCard: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.type == .credit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(transaction.type == .credit ? .green : .red)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(transaction.description)
                    .font(.headline)
                Text(transaction.createdAt.formatted())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(transaction.type == .credit ? "+" : "-")\(transaction.currency) \(String(format: "%.2f", transaction.amount))")
                .foregroundColor(transaction.type == .credit ? .green : .red)
                .font(.headline)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

extension PaymentMethodType {
    var iconName: String {
        switch self {
        case .creditCard, .debitCard:
            return "creditcard.fill"
        case .bankAccount:
            return "building.columns.fill"
        case .digitalWallet:
            return "wallet.pass.fill"
        case .cryptocurrency:
            return "bitcoinsign.circle.fill"
        }
    }
}