//
//  WalletView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-04.
//

import SwiftUI
import UIKit

struct Transaction: Identifiable {
    let id: String
    let title: String
    let amount: Double
    let date: Date
}

struct CardInformationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card Information")
                .font(.headline)
            Text("Card Number: XXXX-XXXX-XXXX-1234")
                .font(.subheadline)
            Text("Expiry Date: 12/25")
                .font(.subheadline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
}

struct WalletView: View {
    @State private var transactions: [Transaction] = []
    @State private var isLoading: Bool = false
    @State private var currentPage: Int = 1
    @State private var selectedMiniProgram: MiniProgram?
    
    var body: some View {
        NavigationView {
            VStack {
                CardInformationView() // Display card information
                
                if transactions.isEmpty {
                    Text("No transactions found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(transactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    .onAppear(perform: loadTransactions)
                }
                
                MiniProgramsView(selectedMiniProgram: $selectedMiniProgram)
            }
            .navigationTitle("Wallet")
            .sheet(item: $selectedMiniProgram) { miniProgram in
                switch miniProgram {
                case .callTaxi:
                    CallTaxiView()
                case .hotelBooking:
                    HotelBookingView()
                case .flightBooking:
                    FlightBookingView()
                case .sendMoney:
                    SendMoneyView()
                case .games:
                    GamesView()
                }
            }
        }
    }
    
    private func loadTransactions() {
        guard !isLoading else { return }
        isLoading = true
        
        // Simulate loading data from a backend API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let newTransactions = [
                Transaction(id: "1", title: "Purchase: Product A", amount: -25.0, date: Date()),
                Transaction(id: "2", title: "Purchase: Product B", amount: -35.0, date: Date()),
                Transaction(id: "3", title: "Deposit", amount: 100.0, date: Date())
                // Additional transactions can be loaded here
            ]
            transactions.append(contentsOf: newTransactions)
            isLoading = false
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @State private var showingAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(transaction.title)
                .font(.headline)
            Text("\(transaction.amount, specifier: "%.2f")")
                .foregroundColor(transaction.amount > 0 ? .green : .red)
                .font(.subheadline)
            Text(transaction.date, style: .date)
                .foregroundColor(.gray)
                .font(.footnote)
        }
        .padding(8)
        .onTapGesture {
            showingAlert = true
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Transaction Details"),
                  message: Text("\(transaction.title)\nAmount: \(transaction.amount, specifier: "%.2f")\nDate: \(transaction.date, formatter: DateFormatter.transactionDateFormatter)"),
                  dismissButton: .default(Text("OK")))
        }
    }
}

extension DateFormatter {
    static let transactionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

enum MiniProgram: String, Identifiable {
    case callTaxi
    case hotelBooking
    case flightBooking
    case sendMoney
    case games
    
    var id: String { self.rawValue }
}

struct MiniProgramsView: View {
    @Binding var selectedMiniProgram: MiniProgram?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Mini Programs")
                .font(.headline)
            
            Button(action: {
                selectedMiniProgram = .callTaxi
            }) {
                Text("Call Taxi")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
            Button(action: {
                selectedMiniProgram = .hotelBooking
            }) {
                Text("Hotel Booking")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
            
            Button(action: {
                selectedMiniProgram = .flightBooking
            }) {
                Text("Flight Booking")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            
            Button(action: {
                selectedMiniProgram = .sendMoney
            }) {
                Text("Send Money")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(8)
            }
            
            Button(action: {
                selectedMiniProgram = .games
            }) {
                Text("Games")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}





