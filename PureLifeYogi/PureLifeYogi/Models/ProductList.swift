//
//  Product.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-03-25.
//

import Foundation

struct Product: Identifiable {
    var id = UUID()
    var name: String
    var image: String
    var price: Int
}

var productlist = [Product(name: "Yoga Roller", image: "P.1", price: 20),
                   Product(name: "Cork Yoga Mat", image: "p.2", price: 50),
                   Product(name: "TPE Yoga Mats", image: "p.3", price: 59),
                   Product(name: "TPE Yoga Mats", image: "P.4", price: 59),
                   Product(name: "T-Shirt", image: "",  price: Int(25.0), category: "Clothing Store"),
                   Product(name: "Laptop", image: ""  price: 1000.0, category: "Electronics Store"),
                   Product(name: "Hammer", image: ""   price: 15.0, category: "Hardware Store"),
                   Product(name: "Drill Machine", image: ""  price: 150.0, category: "Machine Store"),
]
