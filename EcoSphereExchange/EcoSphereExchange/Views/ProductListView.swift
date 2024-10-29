import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()
    @State private var showingFilterSheet = false
    @State private var searchText = ""
    @State private var selectedCategory: Category?
    @State private var sortOption: SortOption = .recommended
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.products.isEmpty {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredProducts) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    ProductCard(product: product)
                                }
                            }
                            
                            if viewModel.hasMoreProducts {
                                ProgressView()
                                    .gridCellUnsizedAxes([.horizontal, .vertical])
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMoreProducts()
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(
                    selectedCategory: $selectedCategory,
                    sortOption: $sortOption
                ) {
                    Task {
                        await viewModel.fetchProducts(
                            category: selectedCategory,
                            sortBy: sortOption
                        )
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .refreshable {
                await viewModel.fetchProducts(
                    category: selectedCategory,
                    sortBy: sortOption
                )
            }
        }
    }
    
    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return viewModel.products
        }
        return viewModel.products.filter { product in
            product.name.localizedCaseInsensitiveContains(searchText) ||
            product.description.localizedCaseInsensitiveContains(searchText) ||
            product.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var filterButton: some View {
        Button(action: { showingFilterSheet = true }) {
            Image(systemName: "slider.horizontal.3")
                .overlay {
                    if selectedCategory != nil || sortOption != .recommended {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .offset(x: 10, y: -10)
                    }
                }
        }
    }
}

struct ProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageURL = product.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text(product.name)
                .font(.headline)
                .lineLimit(2)
            
            Text(product.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text("$\(String(format: "%.2f", product.price))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", product.rating))
                }
                .font(.caption)
            }
            
            if !product.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(product.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: Category?
    @Binding var sortOption: SortOption
    let onApply: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Button("All Categories") {
                        selectedCategory = nil
                    }
                    
                    ForEach(Category.allCases, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            HStack {
                                Text(category.rawValue.capitalized)
                                Spacer()
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Sort By") {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Text(option.description)
                                Spacer()
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedCategory = nil
                        sortOption = .recommended
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}

enum SortOption: CaseIterable {
    case recommended
    case priceLowToHigh
    case priceHighToLow
    case newest
    case bestRated
    
    var description: String {
        switch self {
        case .recommended:
            return "Recommended"
        case .priceLowToHigh:
            return "Price: Low to High"
        case .priceHighToLow:
            return "Price: High to Low"
        case .newest:
            return "Newest First"
        case .bestRated:
            return "Best Rated"
        }
    }
}

extension Category: CaseIterable {}