//
//  WalletView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-04.
//

import SwiftUI

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
    @State private var isHotelBookingPresented = false
    @State private var isSendMoneyPresented = false
    
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
                    HotelBookingView(isPresented: $isHotelBookingPresented)
                case .flightBooking:
                    FlightBookingView()
                case .sendMoney:
                    SendMoneyView(isPresented: $isSendMoneyPresented)
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

enum MiniProgram: String, Identifiable, CaseIterable {
    case callTaxi = "Call Taxi"
    case hotelBooking = "Hotel Booking"
    case flightBooking = "Flight Booking"
    case sendMoney = "Send Money"
    case games = "Games"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .callTaxi:
            return "car.fill"
        case .hotelBooking:
            return "building.fill"
        case .flightBooking:
            return "airplane"
        case .sendMoney:
            return "arrow.left.arrow.right.square.fill"
        case .games:
            return "gamecontroller.fill"
        }
    }
}

struct MiniProgramsView: View {
    @Binding var selectedMiniProgram: MiniProgram?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Mini Programs")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            ForEach(MiniProgram.allCases, id: \.self) { program in
                Button(action: {
                    selectedMiniProgram = program
                }) {
                    HStack {
                        Image(systemName: program.iconName)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(program.color)
                            .clipShape(Circle())
                        
                        Text(program.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.primary)
                            .font(.headline)
                            .padding(.trailing, 10)
                    }
                }
            }
        }
        .padding()
    }
}

extension MiniProgram {
    var color: Color {
        switch self {
        case .callTaxi:
            return Color.blue
        case .hotelBooking:
            return Color.green
        case .flightBooking:
            return Color.orange
        case .sendMoney:
            return Color.purple
        case .games:
            return Color.red
        }
    }
}
