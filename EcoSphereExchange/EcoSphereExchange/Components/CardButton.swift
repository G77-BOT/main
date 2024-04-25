//
//  CardButton.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-03-27.
//

import SwiftUI

struct CartButton: View {
    var numberofproducts: Int
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
        Image(systemName: "cart")
                .padding(.top, 5)
            
            if numberofproducts > 0 {
                Text("\(numberofproducts)")
                    .font(.caption2).bold()
                    .foregroundColor(.white)
                    .frame(width: 15, height: 15)
                    .background(Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0))
                    .cornerRadius(50)
            }
        }
    }
}

struct CardButtoView_Previews: PreviewProvider {
    static var previews: some View {
        CartButton(numberofproducts: 1)
    }
}
