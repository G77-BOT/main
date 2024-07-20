//
//  WishlistView.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-05-14.
//

import SwiftUI
struct WishlistItem: Identifiable {
    var id = UUID()
    var name: String
    var category: String
    var isManifested: Bool
}

class WishlistViewModel: ObservableObject {
    @Published var wishlistItems: [WishlistItem] = []
    
    func addItem(name: String, category: String) {
        let newItem = WishlistItem(name: name, category: category, isManifested: false)
        wishlistItems.append(newItem)
    }
    
    func toggleManifestation(for item: WishlistItem) {
        if let index = wishlistItems.firstIndex(where: { $0.id == item.id }) {
            wishlistItems[index].isManifested.toggle()
        }
    }
}

struct WishlistView: View {
    @StateObject private var viewModel = WishlistViewModel()
    @State private var newItemName: String = ""
    @State private var newItemCategory: String = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.wishlistItems) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name).font(.headline)
                            Text(item.category).font(.subheadline)
                        }
                        Spacer()
                        Image(systemName: item.isManifested ? "checkmark.circle.fill" : "circle")
                            .onTapGesture {
                                viewModel.toggleManifestation(for: item)
                            }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Wishlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        addItem()
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
    }
    
    private func addItem() {
        viewModel.addItem(name: newItemName, category: newItemCategory)
        newItemName = ""
        newItemCategory = ""
    }
    
    private func deleteItems(offsets: IndexSet) {
        viewModel.wishlistItems.remove(atOffsets: offsets)
    }
}

struct WishlistView: View {
    var body: some View {
        // Wishlist view
        Text("Wish list View")
    }
}
