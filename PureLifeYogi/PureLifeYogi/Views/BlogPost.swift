//
//  BlogPost.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-03-27.
//

import SwiftUI
import SafariServices
// Model for Blog Post
struct BlogPost: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let link: URL?
}

// View for Blog Post Row
struct BlogPostRow: View {
    let blogPost: BlogPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(blogPost.title)
                .font(.headline)
            Text(blogPost.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

// View for Blog Post List
struct BlogPostListView: View {
    let blogPosts = [
        BlogPost(title: "Mindfulness Techniques", content: "Cultivating Presence and Awareness in Your Daily Life.", link: URL(string: "https://www.corkyogamats.ca/mindfulness-techniques/")),
        BlogPost(title: "10 Reasons You Should Get A Cork Mat!", content: "Everything You Need to Know About Cork Yoga Mats (but were afraid to ask).", link: URL(string: "https://www.corkyogamats.ca/pop-the-cork-10-reasons-you-should-get-a-cork-mat/")),
        BlogPost(title: "How To Find Which Type Of Yoga Is Right For You", content: "Finding the right type of yoga! for you can be a personal and individual process. Here are some steps to help you determine which type of yoga suits your needs and preferences!.", link: URL(string: "https://www.corkyogamats.ca/how-to-find-which-type-of-yoga-is-right-for-you/")),
    ]
    
    @State private var isShowingSafariView = false
    @State private var safariURL: URL?
    
    var body: some View {
        NavigationView {
            List(blogPosts) { blogPost in
                Button(action: {
                    safariURL = blogPost.link
                    isShowingSafariView = true
                }) {
                    BlogPostRow(blogPost: blogPost)
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Blog")
        }
        .sheet(isPresented: $isShowingSafariView) {
            if let safariURL = safariURL {
                SafariView(url: safariURL)
            }
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


struct BlogPostView_Previews: PreviewProvider {
    static var previews: some View {
        BlogPostView()
    }
}
}
