//
//  AccountView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-04.
//



import SwiftUI

struct AccountView: View {
    @EnvironmentObject var userSession: UserSession // Inject UserSession
    @State private var user: User = User(name: "", phoneNumber: "", email: "", username: "", password: "", confirmPassword: "", address: "")

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NavigationLink(destination: UserInfoView(user: user)) {
                    Text("User Information")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: ChangePasswordView()) {
                    Text("Change Password")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: BillingInfoView()) {
                    Text("Billing Information")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: AffiliateProgramView()) {
                    Text("Affiliate Program")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: WalletView()) {
                    Text("Wallet")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: GeneralSettingsView()) {
                    Text("General Settings")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Button(action: {
                    // Action for Logout
                }) {
                    Text("Logout")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.gray.opacity(0.1)) // Moron color background
            .navigationTitle("Account")
        }
    }
}
