//
//  OrderHistoryView.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-05-14.
//

import SwiftUI
import SwiftUI

struct OrderHistory: Identifiable {
    var id = UUID()
    var date: String
    var items: [String]
    var total: Double
}

struct OrderHistoryView: View {
    @State private var orders: [OrderHistory] = [
        OrderHistory(date: "2024-05-20", items: ["Yoga Mat", "Water Bottle"], total: 35.99),
        OrderHistory(date: "2024-05-18", items: ["Meditation Cushion"], total: 19.99)
    ]
    @State private var showAllReceipts = false
    var body: some View {
        NavigationView {
            List {
                ForEach(orders) { order in
                    VStack(alignment: .leading) {
                        Text("Purchase Date: \(order.date)")
                            .font(.headline)
                        Text("Items Purchased: \(order.items.joined(separator: ", "))")
                        Text("Total: $\(order.total, specifier: "%.2f")")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                Button("Click to See More Past Receipts") {
                    showAllReceipts.toggle()
                }
            }
            .navigationTitle("Order History")
            .sheet(isPresented: $showAllReceipts) {
                AllReceiptsView(orders: $orders)
            }
        }
    }


struct AllReceiptsView: View {
    @Binding var orders: [OrderHistory]

    var body: some View {
        List {
            ForEach(orders, id: \.id) { order in
                VStack(alignment: .leading) {
                    Text("Purchase Date: \(order.date)")
                        .font(.headline)
                    Text("Items Purchased: \(order.items.joined(separator: ", "))")
                    Text("Total: $\(order.total, specifier: "%.2f")")
                }
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .navigationTitle("All Receipts")
    }
}

struct OrderHistoryView: View {
    var body: some View {
        // Order history view
        Text("Order History View")
    }
}

