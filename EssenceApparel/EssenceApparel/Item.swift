//
//  Item.swift
//  EssenceApparel
//
//  Created by mahmmud abdolaziz on 2024-04-15.
//

import Foundation
import SwiftData

@main
struct EssenceApparelApp: App {
    // CoreData persistent container
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
