//
//  FooterView.swift
//  Open Fasion App
//
//  Created by Javid Shaikh on 22/08/23.
//

import SwiftUI

struct FooterView: View {
    var body: some View {
        VStack {
            Image("Openfashion")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            Image("Footer")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView()
    }
}
