//
//  PureLifeYogiApp.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-03-25.
//

import SwiftUI
import SwiftData

@main
struct PureLifeYogiApp: App {
    var sharedModelContainer: ModelContainer = {
        // Define your schema without Item
        let schema = Schema([]) // Empty array for schema
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
