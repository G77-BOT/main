//
//  ContentView.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-03-25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var cartManager = CartManager()
    var Columns = [GridItem(.adaptive(minimum: 160),
                            spacing: 20)]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Columns, spacing: 20) {
                    ForEach(productlist, id: \.id) { product in
                        ProductCard(product: product)
                            .environmentObject(cartManager)
                    }
                }
                .padding()
            }
            .navigationTitle(Text("Yoga Shop"))
            .toolbar {
                NavigationLink {
                    CartView()
                        .environmentObject(cartManager)
                } label: {
                    CartButton(numberofproducts: cartManager.products.count)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    struct ContentView: View {
        var body: some View {
            VStack {
                Text("Your Order")
                    .font(.title)
                
                // Other views
                
                PaymentButton(action: {
                    // Handle payment button tap
                })
                .padding()
                
                // Other views
            }
        }
    }
} 
