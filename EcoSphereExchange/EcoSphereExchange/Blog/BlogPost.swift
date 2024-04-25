//
//  BlogPost.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-05.
//

import SwiftUI
import SafariServices

// Model for Blog Post
struct BlogPost: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let link: URL
}

// View for Blog Post Row
struct BlogPostRow: View {
    let blogPost: BlogPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(blogPost.title)
                .font(.headline)
                .foregroundColor(.white)
            Text(blogPost.content)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.purple)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

// View for Blog Post List
struct BlogPostListView: View {
    @State private var blogPosts: [BlogPost] = []
    @State private var isShowingSafariView = false
    @State private var safariURL: URL?
    
    var body: some View {
        NavigationView {
            VStack {
                List(blogPosts) { blogPost in
                    Button(action: {
                        safariURL = blogPost.link
                        isShowingSafariView = true
                    }) {
                        BlogPostRow(blogPost: blogPost)
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.purple.ignoresSafeArea(edges: .all))
                .onAppear {
                    // Fetch blog posts from backend API
                    fetchBlogPosts()
                }
                .sheet(isPresented: $isShowingSafariView) {
                    if let safariURL = safariURL {
                        SafariView(url: safariURL)
                            .edgesIgnoringSafeArea(.all)
                    }
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
            }
            .navigationTitle("Blog")
        }
        .onReceive(NotificationCenter.default.publisher(for: .newBlogPostNotification)) { _ in
            // Fetch blog posts when new post notification received
            fetchBlogPosts()
        }
    }
    
    private func fetchBlogPosts() {
        // Simulated fetching of blog posts from a backend API
        // Replace this with your actual API call
        
        // Assuming the backend API returns an array of BlogPost objects
        DispatchQueue.main.async {
            blogPosts = [
                BlogPost(title: "Mindfulness Techniques", content: "Cultivating Presence and Awareness in Your Daily Life.", link: URL(string: "https://www.corkyogamats.ca/mindfulness-techniques/")!),
                BlogPost(title: "10 Reasons You Should Get A Cork Mat!", content: "Everything You Need to Know About Cork Yoga Mats (but were afraid to ask).", link: URL(string: "https://www.corkyogamats.ca/pop-the-cork-10-reasons-you-should-get-a-cork-mat/")!),
                BlogPost(title: "How To Find Which Type Of Yoga Is Right For You", content: "Finding the right type of yoga for you can be a personal and individual process. Here are some steps to help you determine which type of yoga suits your needs and preferences.", link: URL(string: "https://www.corkyogamats.ca/how-to-find-which-type-of-yoga-is-right-for-you/")!)
            ]
        }
    }
}

// View for presenting Safari view controller
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: url)
        return safariViewController
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// Notification for new blog post
extension Notification.Name {
    static let newBlogPostNotification = Notification.Name("NewBlogPostNotification")
}

// Example usage of sending a new blog post notification
// NotificationCenter.default.post(name: .newBlogPostNotification, object: nil)


