import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()
    @State private var selectedOrder: Order?
    @State private var showingFilterSheet = false
    @State private var selectedStatus: OrderStatus?
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.orders.isEmpty {
                    EmptyOrdersView()
                } else {
                    ordersList
                }
            }
            .navigationTitle("Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
            .sheet(item: $selectedOrder) { order in
                OrderDetailView(order: order)
            }
            .sheet(isPresented: $showingFilterSheet) {
                OrderFilterView(selectedStatus: $selectedStatus) {
                    Task {
                        await viewModel.fetchOrders(status: selectedStatus)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .refreshable {
                await viewModel.fetchOrders(status: selectedStatus)
            }
        }
    }
    
    private var ordersList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.orders) { order in
                    OrderCard(order: order)
                        .onTapGesture {
                            selectedOrder = order
                        }
                }
                
                if viewModel.hasMoreOrders {
                    ProgressView()
                        .onAppear {
                            Task {
                                await viewModel.loadMoreOrders()
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    private var filterButton: some View {
        Button(action: { showingFilterSheet = true }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .overlay {
                    if selectedStatus != nil {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .offset(x: 10, y: -10)
                    }
                }
        }
    }
}

struct OrderCard: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Order #\(order.id.uuidString.prefix(8))")
                    .font(.headline)
                Spacer()
                Text(order.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(order.items.count) items")
                        .font(.subheadline)
                    Text("Total: \(order.total.formatted(.currency(code: "USD")))")
                        .font(.headline)
                }
                
                Spacer()
                
                OrderStatusBadge(status: order.status)
            }
            
            if let trackingNumber = order.trackingNumber {
                HStack {
                    Image(systemName: "shippingbox.fill")
                    Text("Tracking: \(trackingNumber)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct OrderStatusBadge: View {
    let status: OrderStatus
    
    var backgroundColor: Color {
        switch status {
        case .pending:
            return .yellow
        case .confirmed:
            return .blue
        case .processing:
            return .orange
        case .shipped:
            return .purple
        case .delivered:
            return .green
        case .cancelled:
            return .red
        case .returned:
            return .gray
        case .refunded:
            return .pink
        }
    }
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(backgroundColor)
            .cornerRadius(8)
    }
}

struct EmptyOrdersView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Orders Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("When you place orders, they will appear here")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: ProductListView()) {
                Text("Start Shopping")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct OrderFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedStatus: OrderStatus?
    let onApply: () -> Void
    
    private let statuses: [OrderStatus] = OrderStatus.allCases
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("All Orders") {
                        selectedStatus = nil
                        onApply()
                        dismiss()
                    }
                    
                    ForEach(statuses, id: \.self) { status in
                        Button {
                            selectedStatus = status
                            onApply()
                            dismiss()
                        } label: {
                            HStack {
                                Text(status.rawValue.capitalized)
                                Spacer()
                                if selectedStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Orders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension OrderStatus: CaseIterable {}