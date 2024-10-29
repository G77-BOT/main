import SwiftUI
import SwiftData

struct ItemListView: View {
    @StateObject private var viewModel = ItemListViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterBar
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    categoryFilter
                }
                .padding(.vertical, 8)
                
                // Item List
                itemList
            }
            .navigationTitle("Browse Items")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(
                    filterOptions: $viewModel.filterOptions,
                    sortOption: $viewModel.sortOption
                )
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
        .task {
            await viewModel.loadItems()
        }
    }
    
    // MARK: - Subviews
    
    private var searchAndFilterBar: some View {
        HStack(spacing: 12) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search items...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
            .cornerRadius(10)
        }
        .padding()
    }
    
    private var categoryFilter: some View {
        HStack(spacing: 12) {
            ForEach(ItemCategory.allCases, id: \.self) { category in
                CategoryButton(
                    category: category,
                    isSelected: viewModel.selectedCategory == category,
                    action: { viewModel.filterItems(by: category) }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var itemList: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(viewModel.filteredItems) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        ItemCard(item: item)
                            .task {
                                await viewModel.loadMoreIfNeeded(currentItem: item)
                            }
                    }
                }
            }
            .padding()
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
        }
        .refreshable {
            await viewModel.refreshItems()
        }
    }
    
    private var filterButton: some View {
        Button {
            showingFilterSheet = true
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    // MARK: - Private Properties
    
    @State private var showingFilterSheet = false
    @State private var showingError = false
}

// MARK: - Supporting Views

struct CategoryButton: View {
    let category: ItemCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ItemCard: View {
    let item: Item
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Item Image
            AsyncImage(url: URL(string: item.images.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Item Details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(item.formattedPrice)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                
                HStack {
                    if item.rating != nil {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", item.rating!))
                        }
                    }
                    
                    Spacer()
                    
                    if item.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                    }
                }
                .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct FilterView: View {
    @Binding var filterOptions: FilterOptions
    @Binding var sortOption: SortOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Sort Options
                Section("Sort By") {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Price Range
                Section("Price Range") {
                    HStack {
                        TextField("Min", value: $filterOptions.minPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                        Text("-")
                        TextField("Max", value: $filterOptions.maxPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                    }
                }
                
                // Condition
                Section("Condition") {
                    ForEach(ItemCondition.allCases, id: \.self) { condition in
                        Toggle(condition.rawValue, isOn: conditionBinding(for: condition))
                    }
                }
                
                // Other Filters
                Section("Other Filters") {
                    Toggle("Available Items Only", isOn: $filterOptions.onlyAvailable)
                    Toggle("Verified Sellers Only", isOn: $filterOptions.onlyVerifiedSellers)
                    Toggle("Free Shipping Only", isOn: $filterOptions.freeShippingOnly)
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func conditionBinding(for condition: ItemCondition) -> Binding<Bool> {
        Binding(
            get: { filterOptions.conditions.contains(condition) },
            set: { isSelected in
                if isSelected {
                    filterOptions.conditions.insert(condition)
                } else {
                    filterOptions.conditions.remove(condition)
                }
            }
        )
    }
    
    private func resetFilters() {
        filterOptions = FilterOptions()
        sortOption = .recommended
    }
}

#Preview {
    ItemListView()
}