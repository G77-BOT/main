//
//  Item.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-03-25.
//

import Foundation

struct Item {
    let id: UUID
    let name: String
    let description: String
    // Add more properties as needed
    
    init(id: UUID = UUID(), name: String, description: String) {
        self.id = id
        self.name = name
        self.description = description
        // Initialize other properties as needed
    }
}
