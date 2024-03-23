//
//  Item.swift
//  ShiftShop
//
//  Created by mahmmud abdolaziz on 2024-03-23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
