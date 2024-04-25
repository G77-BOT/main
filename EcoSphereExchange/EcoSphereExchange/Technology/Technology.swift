//
//  Technology.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-05.
//


import SafariServices
import SwiftUI


// View for Technology Article Row
struct TechnologyArticleRow: View {
    let technologyArticle: TechnologyArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(technologyArticle.title)
                .font(.headline)
                .foregroundColor(.black) // Change text color to black
            Text(technologyArticle.content)
                .font(.subheadline)
                .foregroundColor(.black) // Change text color to black
                .lineLimit(2)
            
            Button(action: {
                // Open link within the app using SafariViewController
                if let url = technologyArticle.link {
                    let safariViewController = SFSafariViewController(url: url)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        if let window = windowScene.windows.first {
                            window.rootViewController?.present(safariViewController, animated: true, completion: nil)
                        }
                    }
                }
            }) {
                if let imageUrl = technologyArticle.imageUrl {
                    Image(imageUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .cornerRadius(10)
                } else {
                    Text("Read Article")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.white) // Change background color to white
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// View for Technology Article List
struct TechnologyArticleListView: View {
    @State private var additionalArticles: [TechnologyArticle] = [] // State variable to store additional articles
    
    let technologyArticles = [
        TechnologyArticle(title: "New-Age Yoga Now Powered by AI", content: "How Yoga blends with Technology.", imageUrl: "img.2", link: URL(string: "https://articles.xebia.com/new-age-yoga-now-powered-by-ai")),
        TechnologyArticle(title: "Artificial Intelligence", content: "A.I. Is Learning What It Means to Be Alive.", imageUrl: "img4", link: URL(string: "https://www.nytimes.com/spotlight/artificial-intelligence")),
        TechnologyArticle(title: "Will AI Take Over The World? Or Will You Take Charge Of Your World?", content: "There’s been a lot of scary talk going around lately. Artificial intelligence is getting more powerful — especially the new generative AI that can write code,....!!!!", imageUrl: "img.5", link: URL(string: "https://www.forbes.com/sites/forbesbooksauthors/2023/07/17/will-ai-take-over-the-world-or-will-you-take-charge-of-your-world/?sh=49a6c52739c4"))
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(technologyArticles + additionalArticles) { technologyArticle in
                    TechnologyArticleRow(technologyArticle: technologyArticle)
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Technology")
        .background(Color(UIColor.systemGray6)) // Change background color to a lighter shade
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Add more articles
                    additionalArticles.append(contentsOf: [
                        TechnologyArticle(title: "Quantum Computing: The Next Frontier", content: "Exploring the possibilities of quantum computing.", imageUrl: "img.6", link: URL(string: "https://www.ibm.com/quantum-computing/learn/what-is-quantum-computing/")),
                        TechnologyArticle(title: "The Rise of Machine Learning in Healthcare", content: "How machine learning is revolutionizing healthcare.", imageUrl: "img.7", link: URL(string: "https://www.nature.com/articles/s41591-021-01516-9"))
                    ])
                }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
    }
}
