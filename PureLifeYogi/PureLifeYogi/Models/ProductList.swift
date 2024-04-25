//
//  Product.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-03-25.
//

import Foundation

struct ProductList: Identifiable {
    var id = UUID()
    var name: String
    var image: String
    var price: Int
}

var productlist = [ProductList(name: "Yoga Roller", image: "P.1", price: 20),
                   ProductList(name: "Cork Yoga Mat", image: "p.2", price: 50),
                   ProductList(name: "TPE Yoga Mats", image: "p.3", price: 59),
                   ProductList(name: "TPE Yoga Mats", image: "P.4", price: 59),
                   
]
