import SwiftUI
import SwiftData

struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let user = viewModel.user {
                    profileContent(user)
                } else {
                    loginPrompt
                }
            }
            .navigationTitle("Profile")
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(viewModel: viewModel)
        }
    }
    
    private var loadingView: some View {
        ProgressView("Loading profile...")
            .progressViewStyle(.circular)
    }
    
    private var loginPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Sign in to view your profile")
                .font(.title2)
                .fontWeight(.medium)
            
            NavigationLink {
                LoginView()
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private func profileContent(_ user: User) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                profileHeader(user)
                
                // Stats
                statsGrid(user)
                
                // Content Sections
                Group {
                    // Listed Items
                    sectionHeader("Listed Items")
                    listedItemsGrid
                    
                    // Purchase History
                    sectionHeader("Purchase History")
                    purchaseHistoryList
                    
                    // Favorite Items
                    sectionHeader("Favorites")
                    favoriteItemsGrid
                }
                .padding(.horizontal)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditProfile = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .refreshable {
            viewModel.loadUserProfile()
        }
    }
    
    private func profileHeader(_ user: User) -> some View {
        VStack(spacing: 12) {
            // Profile Image
            if let imageURL = user.profileImage {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .shadow(radius: 2)
                )
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 4) {
                Text(user.username)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if user.isVerified {
                    Label("Verified Seller", systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                if let bio = user.biography {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
    }
    
    private func statsGrid(_ user: User) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 20
        ) {
            StatCard(title: "Listed", value: "\(user.stats.itemsListed)")
            StatCard(title: "Sold", value: "\(user.stats.successfulTransactions)")
            StatCard(title: "Rating", value: String(format: "%.1f", user.reputation))
        }
        .padding(.horizontal)
    }
    
    private var listedItemsGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.fixed(200))], spacing: 16) {
                ForEach(viewModel.listedItems) { item in
                    ItemCard(item: item)
                        .frame(width: 160)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var purchaseHistoryList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.purchaseHistory) { order in
                OrderCard(order: order)
            }
        }
    }
    
    private var favoriteItemsGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.fixed(200))], spacing: 16) {
                ForEach(viewModel.favoriteItems) { item in
                    ItemCard(item: item)
                        .frame(width: 160)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            NavigationLink("See All") {
                // Navigate to full list view
            }
            .font(.subheadline)
        }
    }
    
    // MARK: - Private Properties
    
    @State private var showingError = false
    @State private var showingEditProfile = false
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct OrderCard: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Order #\(order.id.prefix(8))")
                    .font(.headline)
                Spacer()
                OrderStatusBadge(status: order.status)
            }
            
            HStack {
                Text("\(order.items.count) items")
                Spacer()
                Text(formatPrice(order.total))
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            
            Text(formatDate(order.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func formatPrice(_ price: Double) -> String {
        return String(format: "$%.2f", price)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct OrderStatusBadge: View {
    let status: OrderStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending:
            return .orange
        case .processing:
            return .blue
        case .shipped:
            return .purple
        case .delivered:
            return .green
        case .canceled:
            return .red
        case .refunded:
            return .gray
        case .failed:
            return .pink
        }
    }
}

struct EditProfileView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Profile Image
                    HStack {
                        Spacer()
                        if let imageData = viewModel.profileImage,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else if let imageURL = viewModel.user?.profileImage {
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color(.systemGray5))
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .onTapGesture {
                        showingImagePicker = true
                    }
                }
                
                Section("Profile Information") {
                    TextField("Username", text: $viewModel.updatedUsername)
                    TextField("Email", text: $viewModel.updatedEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    TextField("Biography", text: $viewModel.updatedBio, axis: .vertical)
                        .lineLimit(5)
                }
                
                Section("Location") {
                    // Add location fields
                }
                
                Section("Preferences") {
                    NavigationLink("Notification Settings") {
                        NotificationSettingsView(preferences: viewModel.user?.notification ?? NotificationPreferences())
                    }
                    
                    NavigationLink("Privacy Settings") {
                        PrivacySettingsView(settings: viewModel.user?.settings.privacy ?? PrivacySettings())
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(imageData: $viewModel.profileImage)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
    }
    
    private var isValid: Bool {
        !viewModel.updatedUsername.isEmpty &&
        !viewModel.updatedEmail.isEmpty
    }
    
    private func saveProfile() {
        Task {
            do {
                try await viewModel.updateProfile()
                dismiss()
            } catch {
                showingError = true
            }
        }
    }
    
    @State private var showingError = false
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.editedImage] as? UIImage {
                parent.imageData = image.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    UserProfileView()
}