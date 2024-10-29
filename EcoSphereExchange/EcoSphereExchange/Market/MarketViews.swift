//
//  MarketViews.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-05.
//


import SwiftUI
import Foundation


// WebSocket implementation for real-time product updates
class MarketWebSocket {
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected: Bool = false

    func connect() {
        guard !isConnected else {
            print("Already connected to the WebSocket.")
            return
        }

        let url = URL(string: "wss://your-websocket-server.com")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        receiveMessage()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        print("Disconnected from WebSocket.")
    }

    private func receiveMessage() {
        webSocketTask?.receive { result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
                self.isConnected = false
                return
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessage()
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            print("Received data: \(data)")
        case .string(let text):
            print("Received text: \(text)")
        @unknown default:
            print("Unknown message type received.")
        }
    }

    func sendMessage(_ message: String) {
        guard isConnected else {
            print("Cannot send message, WebSocket is not connected.")
            return
        }

        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            } else {
                print("Message sent: \(message)")
            }
        }
    }
}

final class MarketWebSocketManager: ObservableObject {
    private var heartbeatTimer: Timer?
    
    deinit {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func setupHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
}

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

enum SortOption: String, CaseIterable {
        case nameAsc = "Name (A-Z)"
        case nameDesc = "Name (Z-A)"
        case priceLowHigh = "Price (Low-High)"
        case priceHighLow = "Price (High-Low)"
        case rating = "Rating"
        case newest = "Newest"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(searchText: $searchText, isSearching: $isSearching, companies: companies, factories: factories)
                
                // Sorting Menu
                Menu {
                    ForEach(SortingOption.allCases, id: \.self) { option in
                        Button(action: {
                            selectedSortingOption = option
                        }) {
                            Text(option.rawValue)
                        }
                    }
                } label: {
                    Text("Sort by \(selectedSortingOption.rawValue)")
                        .fontWeight(.bold)
                        .padding()
                }
                
                List {
                    // Sorting the list based on selected option
                    let sortedCompanies = sortCompanies(companies: companies, option: selectedSortingOption)
                    let sortedFactories = sortFactories(factories: factories, option: selectedSortingOption)
                    
                    if isSearching {
                        // Your existing search functionality...
                    } else {
                        ForEach(sortedCompanies) { company in
                            NavigationLink(destination: CompanyDetailView(company: company)) {
                                CompanyRow(company: company)
                            }
                        }
                        ForEach(sortedFactories) { factory in
                            NavigationLink(destination: FactoryDetailView(factory: factory)) {
                                FactoryRow(factory: factory)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                // Checkout button
                NavigationLink(destination: CheckoutView()) {
                    Text("Proceed to Checkout")
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationBarTitle("Market")
            .navigationBarItems(
                leading: NavigationLink(destination: CartView()) {
                    Image(systemName: "cart")
                },
                trailing: Menu {
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

    private func sortProducts(products: [Product], option: SortingOption) -> [Product] {
        switch option {
        case .name:
            return products.sorted { $0.name < $1.name }
        case .priceLowHigh:
            return products.sorted { $0.price < $1.price }
        case .priceHighLow:
            return products.sorted { $0.price > $1.price }
        case .rating:
            return products.sorted { $0.rating > $1.rating }
        case .newest:
            return products.sorted { $0.date > $1.date }
        }
    }
    
    private func sortFactories(factories: [Factory], option: SortingOption) -> [Factory] {
        switch option {
        case .name:
            return factories.sorted { $0.name < $1.name }
        case .address:
            return factories.sorted { $0.address < $1.address }
        }
    }

    func toggleWishlist(for productId: UUID) {
        if wishlist.contains(productId) {
            wishlist.remove(productId)
        } else {
            wishlist.insert(productId)
        }
    }
    
    private func sortCompanies(companies: [Company], option: SortingOption) -> [Company] {
        switch option {
        case .name:
            return companies.sorted { $0.name < $1.name }
        case .address:
            return companies.sorted { $0.address < $1.address }
        }
    }
    
    private func sortFactories(factories: [Factory], option: SortingOption) -> [Factory] {
        switch option {
        case .name:
            return factories.sorted { $0.name < $1.name }
        case .address:
            return factories.sorted { $0.address < $1.address }
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

struct ProductGridView: View {
    let products: [Product]
    let onProductTap: (Product) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(products) { product in
                    ProductGridItem(product: product)
                        .onTapGesture {
                            onProductTap(product)
                        }
                }
            }
            .padding()
        }
    }
}

func getRecommendedProducts(for product: Product) -> [Product] {
    // Implementation for product recommendations
    return products.filter { $0.category == product.category && $0.id != product.id }
        .sorted { $0.rating > $1.rating }
        .prefix(5)
        .map { $0 }
}


// MARK: - Enhanced Image Loading
struct CachedAsyncImage<Content: View>: View {
    private let url: URL
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content
    
    init(
        url: URL,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
    }
    
    var body: some View {
        AsyncImage(
            url: url,
            scale: scale,
            transaction: transaction,
            content: { phase in
                cacheAndRender(phase: phase)
            }
        )
    }
    
    private func cacheAndRender(phase: AsyncImagePhase) -> some View {
        if case .success(let image) = phase {
            ImageCache.shared.set(image, for: url)
        }
        return content(phase)
    }
}

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let maxCacheSize = 100 * 1024 * 1024 // 100MB
    
    init() {
        cache.totalCostLimit = maxCacheSize
    }
    
    func set(_ image: UIImage, for url: URL) {
        let cost = image.estimatedMemoryUsage
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
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
            VStack {
                List {
                    ForEach(cart.items) { item in
                        HStack {
                            Text("\(item.product.name) - Quantity: \(item.quantity)")
                            Spacer()
                            Text("$\(String(format: "%.2f", item.product.price * Double(item.quantity)))")
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                
                if cart.items.isEmpty {
                    Text("Your cart is empty.")
                        .font(.headline)
                        .padding()
                } else {
                    Button(action: {
                        showingCheckout = true
                    }) {
                        Text("Proceed to Checkout")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .sheet(isPresented: $showingCheckout) {
                        CheckoutView()
                    }
                }
            }
            .navigationBarTitle("Cart")
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        cart.items.remove(atOffsets: offsets)
    }
}
// Quantity bounds checking
struct CartManager {
    private let maxQuantityPerItem = 99
    
    func validateQuantity(_ quantity: Int, for product: Product) throws {
        guard quantity > 0, quantity <= maxQuantityPerItem else {
            throw ValidationError.invalidQuantity
        }
        
        let currentQuantity = getCurrentQuantity(for: product)
        guard (currentQuantity + quantity) <= maxQuantityPerItem else {
            throw ValidationError.exceededMaxQuantity
        }
    }
}
// Solution for CartManager race conditions
final class CartManager: ObservableObject {
    private let queue = DispatchQueue(label: "com.market.cart", attributes: .concurrent)
    private var _items: [CartItem] = []
    
    var items: [CartItem] {
        queue.sync { _items }
    }
    
    func addItem(_ item: CartItem) {
        queue.async(flags: .barrier) {
            self._items.append(item)
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
}
final class CartStateManager: ObservableObject {
    static let shared = CartStateManager()
    @Published private(set) var cartState: CartState
    private let persistence: CartPersistence
    
    func updateCart(_ items: [CartItem]) {
        Task {
            await MainActor.run {
                cartState.items = items
                persistence.save(items)
                NotificationCenter.default.post(name: .cartDidUpdate, object: nil)
            }
        }
    }
    
    func synchronizeAcrossViews() {
        NotificationCenter.default.publisher(for: .cartDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshCartState()
            }
            .store(in: &cancellables)
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
// Solution for async operation cancellation
final class ProductService {
    private var cancellables = Set<AnyCancellable>()
    
    func fetchProducts() async throws -> [Product] {
        try await withTaskCancellationHandler {
            try await performFetch()
        } onCancel: {
            cancellables.forEach { $0.cancel() }
        }
    }
}
// Product price validation
struct Product {
    let price: Decimal
    
    init(price: Decimal) throws {
        guard price >= 0, price <= 999999.99 else {
            throw ValidationError.invalidPrice
        }
        self.price = price
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

// Current issue: Cart state inconsistency across views
// Solution: Implement central cart state management
class CartManager: ObservableObject {
    @Published private(set) var items: [CartItem] = []
    private let persistenceManager = PersistenceManager()
    
    func syncCart() {
        persistenceManager.saveCart(items)
        NotificationCenter.default.post(name: .cartDidUpdate, object: nil)
    }
}

// Implement lazy loading for product images
struct LazyImageLoader {
    func loadImage(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
                case .empty: ProgressView()
                case .success(let image): image.resizable()
                case .failure(_): Image(systemName: "photo")
                @unknown default: EmptyView()
            }
        }
    }
}
final class MarketViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published var searchText = ""
    @Published var isSearching = false
    @Published var selectedProduct: Product?
    
    private let productService: ProductService
    
    var filteredProducts: [Product] {
        guard !searchText.isEmpty else { return products }
        return products.filter { product in
            product.name.localizedCaseInsensitiveContains(searchText) ||
            product.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    @MainActor
    func refreshProducts() async {
        do {
            products = try await productService.fetchProducts()
        } catch {
            // Handle error appropriately
        }
    }
}
extension MarketViewModel {
    func setupBindings() {
        // Use capture lists consistently
        cartManager.addObserver { [weak self] items in
            self?.updateCartState(items)
        }
    }
}
// Network error recovery strategy
final class NetworkManager {
    private let retryLimit = 3
    private let retryDelay: TimeInterval = 1.0
    
    func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...retryLimit {
            do {
                return try await URLSession.shared.data(for: request).decode()
            } catch {
                lastError = error
                if attempt < retryLimit {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }
        throw lastError ?? URLError(.unknown)
    }
}

// User feedback for error states
struct ErrorView: View {
    let error: MarketError
    let retryAction: () -> Void
    
    var body: some View {
        VStack {
            Text(error.userFriendlyMessage)
            Button("Retry") {
                retryAction()
            }
        }
        .alert("Error", isPresented: .constant(true)) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error.userFriendlyMessage)
        }
    }
}

// Add caching for filtered products
private var cachedFilteredProducts: [Product] = []
private var lastFilterHash: Int = 0

private func updateFilteredProductsCache() {
    let newHash = "\(searchText)\(selectedCategories)\(priceRange)\(sortOption)".hashValue
    if newHash != lastFilterHash {
        cachedFilteredProducts = computeFilteredProducts()
        lastFilterHash = newHash
    }
}

struct ProductAnalytics {
    var viewCount: Int
    var clickThroughRate: Double
    var conversionRate: Double
    
    func trackProductView(productId: UUID) {
        // Implementation for analytics tracking
    }
}

enum MarketError: Error {
    case invalidPrice
    case outOfStock
    case compareListFull
    case networkError
}

func handleMarketError(_ error: MarketError) {
    // Implementation for error handling
}
func getRecommendedProducts(for product: Product) -> [Product] {
    // Implementation for product recommendations
    return products.filter { $0.category == product.category && $0.id != product.id }
        .sorted { $0.rating > $1.rating }
        .prefix(5)
        .map { $0 }
}
func checkStockAvailability(for productId: UUID) -> Bool {
    guard let product = products.first(where: { $0.id == productId }) else { return false }
    return product.stockLevel > 0
}



// Implement pagination for large product lists
private let pageSize = 20
@Published var currentPage = 1

var paginatedProducts: [Product] {
    let startIndex = (currentPage - 1) * pageSize
    return filteredProducts[startIndex..<min(startIndex + pageSize, filteredProducts.count)].map { $0 }
}
// Add state restoration for app suspension/resume
func saveState() {
    UserDefaults.standard.set(try? JSONEncoder().encode(wishlist), forKey: "wishlist")
    UserDefaults.standard.set(try? JSONEncoder().encode(cartItems), forKey: "cartItems")
}

func restoreState() {
    if let wishlistData = UserDefaults.standard.data(forKey: "wishlist") {
        wishlist = (try? JSONDecoder().decode(Set<UUID>.self, from: wishlistData)) ?? []
    }
}
