import SwiftUI

struct SendMoneyView: View {
    @StateObject private var viewModel = SendMoneyViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Payment Platform Selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(PaymentPlatform.allCases) { platform in
                            PlatformButton(
                                platform: platform,
                                isSelected: viewModel.selectedPlatform == platform
                            ) {
                                viewModel.selectedPlatform = platform
                            }
                        }
                    }
                    .padding()
                }
                
                // Transfer Form
                Form {
                    Section(header: Text("Recipient Details")) {
                        TextField("Recipient ID/Email", text: $viewModel.recipientId)
                        
                        if viewModel.shouldShowRecipientName {
                            Text(viewModel.recipientName)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Section(header: Text("Amount")) {
                        HStack {
                            TextField("Amount", text: $viewModel.amount)
                                .keyboardType(.decimalPad)
                            
                            Picker("Currency", selection: $viewModel.selectedCurrency) {
                                ForEach(Currency.allCases) { currency in
                                    Text(currency.code).tag(currency)
                                }
                            }
                        }
                        
                        if let exchangeRate = viewModel.exchangeRate {
                            Text("Exchange Rate: 1 \(viewModel.selectedCurrency.code) = \(String(format: "%.2f", exchangeRate)) \(viewModel.recipientCurrency.code)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Section(header: Text("Transfer Options")) {
                        Picker("Transfer Speed", selection: $viewModel.transferSpeed) {
                            ForEach(TransferSpeed.allCases) { speed in
                                Text(speed.description).tag(speed)
                            }
                        }
                        
                        if let fee = viewModel.transferFee {
                            HStack {
                                Text("Transfer Fee")
                                Spacer()
                                Text("\(viewModel.selectedCurrency.symbol)\(String(format: "%.2f", fee))")
                            }
                        }
                    }
                    
                    Section {
                        Button(action: viewModel.initiateTransfer) {
                            if viewModel.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Send Money")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canInitiateTransfer ? Color.blue : Color.gray)
                        .cornerRadius(10)
                        .disabled(!viewModel.canInitiateTransfer || viewModel.isProcessing)
                    }
                }
            }
            .navigationTitle("Send Money")
            .alert("Transfer Status", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .sheet(isPresented: $viewModel.showingTransferConfirmation) {
                TransferConfirmationView(viewModel: viewModel)
            }
        }
    }
}

struct PlatformButton: View {
    let platform: PaymentPlatform
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(platform.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                
                Text(platform.name)
                    .font(.caption)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 1)
            )
        }
        .foregroundColor(isSelected ? .blue : .primary)
    }
}

struct TransferConfirmationView: View {
    @ObservedObject var viewModel: SendMoneyViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Transfer Details
                Group {
                    TransferDetailRow(title: "From", value: viewModel.senderName)
                    TransferDetailRow(title: "To", value: viewModel.recipientName)
                    TransferDetailRow(
                        title: "Amount",
                        value: "\(viewModel.selectedCurrency.symbol)\(viewModel.amount)"
                    )
                    if let fee = viewModel.transferFee {
                        TransferDetailRow(
                            title: "Fee",
                            value: "\(viewModel.selectedCurrency.symbol)\(String(format: "%.2f", fee))"
                        )
                    }
                    TransferDetailRow(
                        title: "Total",
                        value: "\(viewModel.selectedCurrency.symbol)\(viewModel.totalAmount)"
                    )
                    TransferDetailRow(title: "Platform", value: viewModel.selectedPlatform.name)
                    TransferDetailRow(title: "Speed", value: viewModel.transferSpeed.description)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Confirm Button
                Button(action: {
                    viewModel.confirmTransfer()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Confirm Transfer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Confirm Transfer")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct TransferDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

class SendMoneyViewModel: ObservableObject {
    @Published var selectedPlatform: PaymentPlatform = .paypal
    @Published var recipientId = ""
    @Published var amount = ""
    @Published var selectedCurrency: Currency = .usd
    @Published var transferSpeed: TransferSpeed = .standard
    @Published var isProcessing = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showingTransferConfirmation = false
    
    private let securityAlgorithm = PaymentSecurityAlgorithm()
    private let dailyLimit: Double = 3000.0
    
    // Computed Properties
    var recipientName: String {
        // Implement recipient name lookup
        return "John Doe"
    }
    
    var senderName: String {
        // Implement sender name
        return "Current User"
    }
    
    var shouldShowRecipientName: Bool {
        !recipientId.isEmpty
    }
    
    var recipientCurrency: Currency {
        // Implement recipient currency detection
        return .eur
    }
    
    var exchangeRate: Double? {
        // Implement exchange rate calculation
        return 1.2
    }
    
    var transferFee: Double? {
        guard let amount = Double(amount) else { return nil }
        return calculateTransferFee(amount: amount, speed: transferSpeed)
    }
    
    var totalAmount: String {
        guard let amount = Double(amount),
              let fee = transferFee else { return "0.00" }
        return String(format: "%.2f", amount + fee)
    }
    
    var canInitiateTransfer: Bool {
        guard let amount = Double(amount),
              amount > 0,
              !recipientId.isEmpty else { return false }
        return true
    }
    
    func initiateTransfer() {
        guard let amount = Double(amount) else { return }
        
        let transaction = Transaction(
            id: UUID().uuidString,
            userId: "current_user_id",
            amount: amount,
            timestamp: Date(),
            location: Location(latitude: 0, longitude: 0, country: "US", city: "New York"),
            deviceInfo: DeviceInfo(
                deviceId: "device_id",
                deviceType: "iPhone",
                operatingSystem: "iOS",
                ipAddress: "127.0.0.1"
            ),
            paymentMethod: .paypal
        )
        
        let analysis = securityAlgorithm.analyzeTransaction(transaction)
        
        if analysis.riskLevel == .high || analysis.riskLevel == .critical {
            alertMessage = "Transfer blocked: High risk transaction detected"
            showAlert = true
            return
        }
        
        if !analysis.limitCheck.withinLimit {
            alertMessage = "Daily transfer limit exceeded. Remaining limit: \(analysis.limitCheck.remainingLimit)"
            showAlert = true
            return
        }
        
        showingTransferConfirmation = true
    }
    
    func confirmTransfer() {
        isProcessing = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isProcessing = false
            self.alertMessage = "Transfer completed successfully!"
            self.showAlert = true
            self.resetForm()
        }
    }
    
    private func calculateTransferFee(amount: Double, speed: TransferSpeed) -> Double {
        switch speed {
        case .instant:
            return amount * 0.05 // 5% fee
        case .express:
            return amount * 0.03 // 3% fee
        case .standard:
            return amount * 0.01 // 1% fee
        }
    }
    
    private func resetForm() {
        recipientId = ""
        amount = ""
        selectedCurrency = .usd
        transferSpeed = .standard
    }
}

enum PaymentPlatform: String, CaseIterable, Identifiable {
    case paypal
    case wechat
    case alipay
    case mpesa
    case airtel
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .paypal: return "PayPal"
        case .wechat: return "WeChat Pay"
        case .alipay: return "Alipay"
        case .mpesa: return "M-PESA"
        case .airtel: return "Airtel Money"
        }
    }
    
    var iconName: String {
        return "icon_\(self.rawValue)"
    }
}

enum Currency: String, CaseIterable, Identifiable {
    case usd
    case eur
    case gbp
    case cny
    case jpy
    
    var id: String { self.rawValue }
    
    var code: String {
        self.rawValue.uppercased()
    }
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .cny: return "¥"
        case .jpy: return "¥"
        }
    }
}

enum TransferSpeed: String, CaseIterable, Identifiable {
    case instant
    case express
    case standard
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .instant: return "Instant (within minutes)"
        case .express: return "Express (1-2 hours)"
        case .standard: return "Standard (1-3 business days)"
        }
    }
}
