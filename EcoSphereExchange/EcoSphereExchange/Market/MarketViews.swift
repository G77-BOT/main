//
//  MarketViews.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-05.
//


import SwiftUI

struct MarketView: View {
    let companies = [
        Company(name: "Pure Life Yogi", address: "130 Woodridge Cres, Ottawa", email: "purelife@corkyogamats.ca", phoneNumber: "+1 613-726-6429", logo: "img", products: [
            Product(name: "Cork Yoga Mats", description: "A sustainable and natural yoga mat made from cork material.", price: 49.99, image: Image("img.g")),
            Product(name: "TPE Yoga Mat", description: "A high-density and eco-friendly yoga mat made from TPE material.", price: 39.99, image: Image("img.g2")),
            Product(name: "Yoga Roller", description: "A foam roller for self-myofascial release and muscle recovery.", price: 19.99, image: Image("img.g3")),
        ]),
        Company(name: "Lululemon", address: "100 Bayshore Dr Unit EE4A, Ottawa", email: "email2@example.com", phoneNumber: "+1 (613) 721-0220", logo: "LuLu", products: [
            Product(name: "Wunderlust Backpack 25L", description: "A day full of plans calls for a backpack full of storage options. The drawstring opening allows for easy access to stowed items, while buckle closures keep your bag securely shut.", price: 99.99, image: Image("img.7")),
            Product(name: "Wunder Under SmoothCover High-Rise Tight 25", description: "Flow, train, or restore in our versatile Wunder Under tights. This version is made from SmoothCover™ fabric for smoothing support as you move.", price: 79.99, image: Image("img.8")),
            Product(name: "Blissfeel 2 Women's Running Shoe", description: "Why you’ll love this", price: 129.99, image: Image("img.9")),
        ]),
    ]
    
    let factories = [
        Factory(name: "Yoga Mat Factory", address: "123 Industrial Ave, Ottawa", products: [
            Product(name: "Bulk Yoga Mats", description: "Wholesale cork yoga mats for studios and retailers.", price: 599.99, image: Image("img.factory1")),
            Product(name: "TPE Rolls", description: "Large rolls of TPE material for manufacturing yoga mats.", price: 899.99, image: Image("img.factory2")),
        ])
    ]
    
    @EnvironmentObject var cart: Cart
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(searchText: $searchText, isSearching: $isSearching, companies: companies, factories: factories)
                List {
                    if isSearching {
                        // Your existing search functionality...
                    } else {
                        ForEach(companies) { company in
                            NavigationLink(destination: CompanyDetailView(company: company)) {
                                CompanyRow(company: company)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitle("Market")
            .navigationBarItems(
                leading: NavigationLink(destination: CartView()) {
                    Image(systemName: "cart")
                },
                trailing: Menu {
                    Button(action: {
                        // Add sorting functionality
                    }) {
                        Text("Sort")
                    }
                    Button(action: {
                        // Add filtering functionality
                    }) {
                        Text("Filter")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            )
            .background(
                Image("background_image")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.5)
            )
        }
        .environmentObject(cart)
    }
}



struct CompanyRow: View {
    let company: Company
    
    var body: some View {
        NavigationLink(destination: CompanyDetailView(company: company)) {
            HStack(spacing: 10) {
                Image(company.logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(company.name)
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(company.address)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompanyDetailView: View {
    let company: Company
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(company.products) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        ProductRow(product: product)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(company.name)
    }
}

struct ProductRow: View {
    let product: Product
    @EnvironmentObject var cart: Cart
    @State private var isAddedToCart = false
    
    var body: some View {
        VStack(alignment: .leading) {
            product.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
            
            Text(product.name)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.red)
                .padding(.horizontal)
            
            Text(product.description)
                .font(.subheadline)
                .foregroundColor(.red)
                .lineLimit(2)
                .padding(.horizontal)
            
            HStack {
                Text("$\(String(format: "%.2f", product.price))")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    addToCart()
                }) {
                    Text(isAddedToCart ? "Added to Cart" : "Shop Now")
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(isAddedToCart ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(isAddedToCart)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
    
    private func addToCart() {
        cart.addItem(product, quantity: 1)
        isAddedToCart = true
    }
}

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let companies: [Company]
    let factories: [Factory]
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search for companies, products, or factories", text: $searchText)
                    .padding(.leading, 24)
                    .foregroundColor(.red)
                
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding()
            }
            .padding(.horizontal)
            .background(Color(.systemGray5))
            .cornerRadius(8)
            .padding(.horizontal)
            .onTapGesture {
                isSearching = true
            }
            
            if isSearching {
                List {
                    ForEach(searchResults(), id: \.id) { item in
                        switch item {
                        case let .company(company):
                            NavigationLink(destination: CompanyDetailView(company: company)) {
                                Text(company.name)
                                    .foregroundColor(.red)
                            }
                        case let .factory(factory):
                            NavigationLink(destination: FactoryDetailView(factory: factory)) {
                                Text(factory.name)
                                    .foregroundColor(.red)
                            }
                        case let .product(product):
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                Text(product.name)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .listStyle(GroupedListStyle())
            }
        }
    }
    
    private func searchResults() -> [SearchItem] {
        _ = searchText.lowercased()
        var results: [SearchItem] = []
        
        results += companies
            .filter { $0.contains(searchText) }
            .map { .company($0) }
        
        results += factories
            .filter { $0.contains(searchText) }
            .map { .factory($0) }
        
        for company in companies {
            results += company.products
                .filter { $0.contains(searchText) }
                .map { .product($0) }
        }
        
        for factory in factories {
            results += factory.products
                .filter { $0.contains(searchText) }
                .map { .product($0) }
        }
        
        return results
    }
}

enum SearchItem: Identifiable {
    var id: UUID {
        switch self {
        case let .company(company):
            return company.id
        case let .factory(factory):
            return factory.id
        case let .product(product):
            return product.id
        }
    }
    
    case company(Company)
    case factory(Factory)
    case product(Product)
}

struct Company: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let email: String
    let phoneNumber: String
    let logo: String
    let products: [Product]
    
    func contains(_ searchText: String) -> Bool {
        return name.localizedCaseInsensitiveContains(searchText) || address.localizedCaseInsensitiveContains(searchText) || email.localizedCaseInsensitiveContains(searchText) || phoneNumber.localizedCaseInsensitiveContains(searchText) || products.contains(where: { $0.contains(searchText) })
    }
}



struct Factory: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let products: [Product]
    
    func contains(_ searchText: String) -> Bool {
        return name.localizedCaseInsensitiveContains(searchText) || address.localizedCaseInsensitiveContains(searchText) || products.contains(where: { $0.contains(searchText) })
    }
}

struct Product: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let price: Double
    let image: Image
    
    func contains(_ searchText: String) -> Bool {
        return name.localizedCaseInsensitiveContains(searchText) || description.localizedCaseInsensitiveContains(searchText)
    }
}

struct CartView: View {
    @EnvironmentObject var cart: Cart
    @State private var showingCheckout = false

    var body: some View {
        NavigationView {
            List {
                ForEach(cart.items) { item in
                    Text("\(item.product.name) - Quantity: \(item.quantity)")
                }
                .onDelete(perform: deleteItems)
            }
            .navigationBarTitle("Cart")
            .navigationBarItems(trailing:
                Button(action: {
                    showingCheckout = true
                }) {
                    Text("Checkout")
                }
            )
            .sheet(isPresented: $showingCheckout) {
                CheckoutView(cart: cart)
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        cart.items.remove(atOffsets: offsets)
    }
}

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject var cart: Cart
    @State private var quantity: Int = 1
    
    var body: some View {
        VStack {
            product.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
            
            Text(product.name)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text(product.description)
                .font(.subheadline)
                .padding(.horizontal)
            
            Stepper("Quantity: \(quantity)", value: $quantity, in: 1...10)
                .padding(.horizontal)
            
            HStack {
                Text("$\(String(format: "%.2f", product.price * Double(quantity)))")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    addToCart()
                }) {
                    Text("Add to Cart")
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle(product.name)
    }
    
    private func addToCart() {
        cart.addItem(product, quantity: quantity)
        quantity = 1
    }
}

struct FactoryDetailView: View {
    let factory: Factory
    
    var body: some View {
        Text("Factory Detail View: \(factory.name)")
    }
}

struct MarketView_Previews: PreviewProvider {
    static var previews: some View {
        MarketView()
            .environmentObject(Cart())
    }
}
