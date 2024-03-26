//
//  SendMoneyView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-07.
//

import SwiftUI

struct SendMoneyView: View {
    @Binding var isPresented: Bool
    
    @State private var recipient: String = ""
    @State private var amount: Double = 0.0
    @State private var selectedBank: Bank?
    @State private var isSendingMoney: Bool = false
    @State private var isShowingConfirmation: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Send Money")
                .font(.title)
            
            Form {
                Section(header: Text("Recipient Details")) {
                    TextField("Recipient", text: $recipient)
                    Picker("Bank", selection: $selectedBank) {
                        ForEach(Bank.allBanks, id: \.self) { bank in
                            Text(bank.name)
                        }
                    }
                }
                
                Section(header: Text("Transfer Details")) {
                    TextField("Amount", value: $amount, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                }
            }
            
            Button(action: {
                sendMoney()
            }) {
                Text("Send Money")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .disabled(recipient.isEmpty || amount <= 0 || selectedBank == nil)
            .alert(isPresented: $isShowingConfirmation) {
                Alert(title: Text("Confirmation"), message: Text("Are you sure you want to send $\(amount) to \(recipient)?"), primaryButton: .default(Text("Yes"), action: sendMoney), secondaryButton: .cancel())
            }
            
            if isSendingMoney {
                ProgressView()
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func sendMoney() {
        // Implement money transfer functionality here
        // Replace the code below with your actual implementation
        
        isSendingMoney = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSendingMoney = false
            isShowingConfirmation = true
        }
    }
}

struct Bank: Hashable {
    let name: String
    
    static let allBanks: [Bank] = [
        Bank(name: "Bank A"),
        Bank(name: "Bank B"),
        Bank(name: "Bank C"),
        Bank(name: "Bank D"),
    ]
}
