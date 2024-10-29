import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject var cartManager: CartManager
    @State private var quantity: Int = 1
    @State private var showingReviewSheet = false
    @State private var showingShareSheet = false
    @State private var isAddedToCart = false
    @State private var showingNotification = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Product Image
                if let imageURL = product.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Product Info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(product.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", product.price))")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    // Rating and Reviews
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(product.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                        Text("(\(product.reviews.count) reviews)")
                            .foregroundColor(.secondary)
                    }
                    
                    // Category and Tags
                    HStack {
                        Text(product.category.rawValue.capitalized)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(product.tags, id: \.self) { tag in
                                    Text(tag)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Description
                    Text("Description")
                        .font(.headline)
                    Text(product.description)
                        .foregroundColor(.secondary)
                    
                    // Stock Status
                    HStack {
                        Image(systemName: product.stock > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(product.stock > 0 ? .green : .red)
                        Text(product.stock > 0 ? "In Stock (\(product.stock) available)" : "Out of Stock")
                            .foregroundColor(product.stock > 0 ? .green : .red)
                    }
                    
                    // Quantity Selector
                    if product.stock > 0 {
                        HStack {
                            Text("Quantity:")
                            Stepper(value: $quantity, in: 1...product.stock) {
                                Text("\(quantity)")
                                    .frame(width: 50)
                                    .padding(.horizontal)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Seller Info
                    VStack(alignment: .leading) {
                        Text("Seller Information")
                            .font(.headline)
                        HStack {
                            Text("Sold by:")
                            Text(product.seller.username)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
                
                // Reviews Section
                VStack(alignment: .leading) {
                    HStack {
                        Text("Customer Reviews")
                            .font(.headline)
                        Spacer()
                        Button("Write a Review") {
                            showingReviewSheet = true
                        }
                        .foregroundColor(.blue)
                    }
                    
                    if product.reviews.isEmpty {
                        Text("No reviews yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(product.reviews) { review in
                            ReviewCard(review: review)
                        }
                    }
                }
                .padding()
            }
        }
        .overlay(
            Group {
                if showingNotification {
                    NotificationBanner(text: "Added to cart", isSuccess: true)
                        .transition(.move(edge: .top))
                        .animation(.easeInOut)
                }
            }
        )
        .navigationBarItems(
            trailing: HStack {
                Button(action: {
                    showingShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                
                if product.stock > 0 {
                    Button(action: addToCart) {
                        Image(systemName: isAddedToCart ? "cart.fill.badge.plus" : "cart.badge.plus")
                    }
                }
            }
        )
        .sheet(isPresented: $showingReviewSheet) {
            WriteReviewView(product: product)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [
                product.name,
                product.description,
                URL(string: product.imageURL ?? "")
            ].compactMap { $0 })
        }
    }
    
    private func addToCart() {
        for _ in 1...quantity {
            cartManager.addToCart(product: product)
        }
        withAnimation {
            isAddedToCart = true
            showingNotification = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingNotification = false
            }
        }
    }
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(0..<5) { index in
                    Image(systemName: index < Int(review.rating) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
                Spacer()
                Text(review.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(review.comment)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct WriteReviewView: View {
    let product: Product
    @Environment(\.presentationMode) var presentationMode
    @State private var rating: Double = 0
    @State private var comment: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rating")) {
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    rating = Double(index + 1)
                                }
                        }
                    }
                }
                
                Section(header: Text("Comment")) {
                    TextEditor(text: $comment)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Write a Review")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Submit") {
                    submitReview()
                }
                .disabled(rating == 0 || comment.isEmpty)
            )
        }
    }
    
    private func submitReview() {
        let review = Review(
            userId: UUID(), // Should be current user's ID
            rating: rating,
            comment: comment
        )
        product.addReview(review)
        presentationMode.wrappedValue.dismiss()
    }
}

struct NotificationBanner: View {
    let text: String
    let isSuccess: Bool
    
    var body: some View {
        Text(text)
            .foregroundColor(.white)
            .padding()
            .background(isSuccess ? Color.green : Color.red)
            .cornerRadius(8)
            .shadow(radius: 4)
            .padding(.top)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}