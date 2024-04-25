//
//  ContentView.swift
//  EssenceApparel
//
//  Created by mahmmud abdolaziz on 2024-04-15.
//

import SwiftUI
import CoreData

// Model for Product
struct Product: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
}

// Model for Blog
struct BlogPost: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
}

// Main ContentView
struct ContentView: View {
    // CoreData context
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    // Fetch products
    @FetchRequest(
        entity: ProductEntity.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ProductEntity.name, ascending: true)
        ]
    ) var products: FetchedResults<ProductEntity>
    
    // State variables for navigation
    @State private var isShowingAccountView = false
    @State private var isShowingMarketView = false
    
    // Other state variables for search, etc.
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    // Display product items
                }
                
                // Other views such as BlogView, MarketView, SearchView, etc.
                
                Spacer()
                
                // Account Button
                Button(action: {
                    self.isShowingAccountView = true
                }) {
                    Image(systemName: "person.circle")
                        .font(.title)
                }
                .sheet(isPresented: $isShowingAccountView) {
                    AccountView()
                }
            }
            .navigationBarTitle("E-Commerce App")
            .navigationBarItems(trailing:
                Button(action: {
                    // Handle logout action
                }) {
                    Text("Logout")
                }
            )
        }
    }
}




// View for displaying market with companies & retailer products
struct MarketView: View {
    var body: some View {
        // Display market view
    }
}

// View for searching products, companies, retailers
struct SearchView: View {
    var body: some View {
        // Search functionality
    }
}

// View for displaying product details
struct ProductDetailView: View {
    // Product entity
    let product: ProductEntity
    
    var body: some View {
        // Display product details
    }
}

// View for adding new products
struct AddProductView: View {
    // CoreData context
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    // State variables for new product
    @State private var name = ""
    @State private var price = ""
    
    var body: some View {
        // Form for adding product
    }
}

// CoreData Product Entity
class ProductEntity: NSManagedObject {
    // Attributes: name (String), price (Double)
}



// CoreData persistent controller
struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "ECommerceDataModel")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
    }
}
