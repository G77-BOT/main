//
//  AccountView.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-04-28.
//

import SwiftUI

// User model
struct User {
    var name: String
    var phoneNumber: String
    var email: String
    var username: String
    var password: String
    var confirmPassword: String
    var address: String
}

// User session
class UserSession: ObservableObject {
    @Published var currentUser: User?
}

struct AccountView: View {
    @EnvironmentObject var userSession: UserSession // Inject UserSession
    @State private var user: User = User(name: "", phoneNumber: "", email: "", username: "", password: "", confirmPassword: "", address: "")

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NavigationLink(destination: UserInfoView()) {
                    AccountRow(title: "User Information", icon: "person")
                }
                
                NavigationLink(destination: OrderHistoryView()) {
                    AccountRow(title: "Order History", icon: "clock")
                }
                
                NavigationLink(destination: WishlistView()) {
                    AccountRow(title: "Wishlist", icon: "heart")
                }
                
                NavigationLink(destination: WalletView()) {
                    AccountRow(title: "Wallet", icon: "creditcard")
                }
                
                NavigationLink(destination: SupportView()) {
                    AccountRow(title: "Support", icon: "questionmark.circle")
                }

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
            .navigationTitle("")
        }
    }
}

struct AccountRow: View {
    var title: String
    var icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
            Text(title)
                .font(.title3)
                .foregroundColor(.black)
                .padding(.leading, 10)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}







// User session, and other views are defined
