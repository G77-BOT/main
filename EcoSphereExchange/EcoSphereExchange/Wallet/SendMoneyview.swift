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
    @State private var selectedService: MoneyTransferService?
    @State private var isSendingMoney: Bool = false
    @State private var isShowingConfirmation: Bool = false
    @State private var transferResult: TransferResult?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Send Money")
                .font(.title)
            
            Form {
                Section(header: Text("Recipient Details")) {
                    TextField("Recipient", text: $recipient)
                    Picker("Money Transfer Service", selection: $selectedService) {
                        ForEach(MoneyTransferService.allServices, id: \.self) { service in
                            Text(service.name)
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
            .disabled(recipient.isEmpty || amount <= 0 || selectedService == nil)
            .alert(isPresented: $isShowingConfirmation) {
                Alert(title: Text("Confirmation"), message: Text("Are you sure you want to send $\(amount) to \(recipient)?"), primaryButton: .default(Text("Yes"), action: sendMoney), secondaryButton: .cancel())
            }
            
            if isSendingMoney {
                ProgressView()
                    .padding()
            }
            
            if let result = transferResult {
                TransferResultView(result: result)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func sendMoney() {
        guard selectedService != nil else { return }
        
        // Implement money transfer functionality here using the selected service
        // Example: integrate with PayPal API
        isSendingMoney = true
        
        PayPalService.transferMoney(to: recipient, amount: amount) { result in
            isSendingMoney = false
            transferResult = result
        }
    }
}

struct TransferResultView: View {
    let result: TransferResult
    
    var body: some View {
        VStack {
            if result.success {
                Text("Transfer Successful")
                    .foregroundColor(.green)
            } else {
                Text("Transfer Failed")
                    .foregroundColor(.red)
            }
            
            Text(result.message)
                .foregroundColor(.black)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct MoneyTransferService: Hashable {
    let name: String
    // Additional properties and configurations for each service can be added here
    
    static let allServices: [MoneyTransferService] = [
        MoneyTransferService(name: "PayPal"),
        MoneyTransferService(name: "Venmo"),
        MoneyTransferService(name: "Alipay"),
        MoneyTransferService(name: "Western Union"),
        MoneyTransferService(name: "Xe"),
        // Add more services as needed
    ]
}

struct TransferResult {
    let success: Bool
    let message: String
}

struct PayPalService {
    static func transferMoney(to recipient: String, amount: Double, completion: @escaping (TransferResult) -> Void) {
        // Integrate with PayPal API to transfer money
        // Placeholder implementation for demonstration
        
        // Simulate a successful transfer
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(TransferResult(success: true, message: "Money transferred successfully via PayPal."))
        }
    }
}
