//
//  BlogPost.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-05.
//

import SwiftUI
import SafariServices

// Model for Blog Post with Codable and additional attributes
struct BlogPost: Codable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let link: URL
    let author: String
    let publishDate: Date
    let readTime: Int
    let category: String
    var likes: Int
    var bookmarked: Bool
}

// Service for managing Blog Posts, API fetching, pagination, caching, etc.
class BlogService: ObservableObject {
    @Published var blogPosts: [BlogPost] = []
    @Published var bookmarkedPosts: [BlogPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let pageSize = 10
    private var currentPage = 1
    private var hasMorePages = true
    
    // Fetch blog posts with pagination and cache handling
    func fetchBlogPosts() async {
        guard hasMorePages else { return }
        
        isLoading = true
        do {
            let newPosts = try await fetchFromAPI()
            DispatchQueue.main.async {
                self.blogPosts.append(contentsOf: newPosts)
                self.currentPage += 1
                self.hasMorePages = newPosts.count == self.pageSize
                self.isLoading = false
                self.cacheBlogs()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.loadCachedBlogs()
            }
        }
    }
    
    // Simulated API call
    private func fetchFromAPI() async throws -> [BlogPost] {
        return [
            BlogPost(
                id: UUID(),
                title: "Mindfulness Techniques",
                content: "Cultivating Presence and Awareness in Your Daily Life.",
                link: URL(string: "https://www.corkyogamats.ca/mindfulness-techniques/")!,
                author: "Sarah Johnson",
                publishDate: Date(),
                readTime: 5,
                category: "Wellness",
                likes: 156,
                bookmarked: false
            ),
            // Add additional posts
        ]
    }
    
    // Cache handling
    private func cacheBlogs() {
        if let encoded = try? JSONEncoder().encode(blogPosts) {
            UserDefaults.standard.set(encoded, forKey: "cachedBlogs")
        }
    }
    
    private func loadCachedBlogs() {
        if let cached = UserDefaults.standard.data(forKey: "cachedBlogs"),
           let decoded = try? JSONDecoder().decode([BlogPost].self, from: cached) {
            self.blogPosts = decoded
        }
    }
    
    // Blog interaction methods
    func toggleBookmark(for post: BlogPost) {
        if let index = blogPosts.firstIndex(where: { $0.id == post.id }) {
            blogPosts[index].bookmarked.toggle()
            updateBookmarkedPosts()
            cacheBlogs()
        }
    }
    
    private func updateBookmarkedPosts() {
        bookmarkedPosts = blogPosts.filter { $0.bookmarked }
    }
    
    func incrementLikes(for post: BlogPost) {
        if let index = blogPosts.firstIndex(where: { $0.id == post.id }) {
            blogPosts[index].likes += 1
            cacheBlogs()
        }
    }
}

// Blog List View with filtering and pagination
struct BlogListView: View {
    @StateObject private var blogService = BlogService()
    @State private var selectedCategory: String?
    @State private var showBookmarksOnly = false
    @State private var safariURL: URL?
    @State private var isShowingSafariView = false
    
    var filteredPosts: [BlogPost] {
        var posts = showBookmarksOnly ? blogService.bookmarkedPosts : blogService.blogPosts
        if let category = selectedCategory {
            posts = posts.filter { $0.category == category }
        }
        return posts
    }
    
    var body: some View {
        NavigationView {
            List(filteredPosts) { post in
                Button(action: {
                    safariURL = post.link
                    isShowingSafariView = true
                }) {
                    BlogPostRow(post: post, blogService: blogService)
                        .onAppear {
                            if post.id == filteredPosts.last?.id {
                                Task {
                                    await blogService.fetchBlogPosts()
                                }
                            }
                        }
                }
            }
            .refreshable {
                Task {
                    await blogService.fetchBlogPosts()
                }
            }
            .overlay(
                Group {
                    if blogService.isLoading {
                        ProgressView()
                    }
                    if let error = blogService.errorMessage {
                        ErrorView(message: error)
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Toggle("Bookmarks", isOn: $showBookmarksOnly)
                        Picker("Category", selection: $selectedCategory) {
                            Text("All").tag(nil as String?)
                            Text("Wellness").tag("Wellness" as String?)
                            Text("Technology").tag("Technology" as String?)
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .navigationTitle("Blog")
            .sheet(isPresented: $isShowingSafariView) {
                if let safariURL = safariURL {
                    SafariView(url: safariURL)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .onAppear {
            Task {
                await blogService.fetchBlogPosts()
            }
        }
    }
}

// Blog Post Row View
struct BlogPostRow: View {
    let post: BlogPost
    let blogService: BlogService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title)
                .font(.headline)
            
            HStack {
                Text(post.author)
                Text("·")
                Text("\(post.readTime) min read")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            Text(post.content)
                .lineLimit(3)
                .font(.body)
            
            HStack {
                Button(action: { blogService.incrementLikes(for: post) }) {
                    Label("\(post.likes)", systemImage: "heart")
                }
                
                Spacer()
                
                Button(action: { blogService.toggleBookmark(for: post) }) {
                    Image(systemName: post.bookmarked ? "bookmark.fill" : "bookmark")
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// Safari View Wrapper for Link Opening
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// Error View to display messages
struct ErrorView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .padding()
            .foregroundColor(.red)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
    }
}
