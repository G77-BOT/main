//
//  ProductRow.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-03-27.
//

import SwiftUI

struct ProductRow: View {
    @EnvironmentObject var cartManager: CartManager
    var product: Product
    var body: some View {
        HStack(spacing: 20) {
            Image (product.image)
                .resizable()
                .aspectRatio (contentMode: .fit)
                .frame(width: 150)
                .cornerRadius(50)
            
            VStack(alignment: .leading,
                   spacing: 10) {
                Text (product.name)
                    .bold()
                
                Text("$\(product.price)")
            }
            Spacer()
            
            Image (systemName: "trash")
                .foregroundColor(Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0))
                .cornerRadius(50)
                .onTapGesture {
                    cartManager.removeFromCart(product: product)
                }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct ProductRow_Previews: PreviewProvider {
    static var previews: some View {
        ProductRow(product: productlist[3])
            .environmentObject(CartManager())
    }
}
