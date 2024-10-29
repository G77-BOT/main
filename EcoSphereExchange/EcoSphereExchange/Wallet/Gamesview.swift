import SwiftUI
import Combine
import GameKit

// MARK: - GameType Enum
enum GameType: String, Identifiable, CaseIterable {
    case cards
    case candy
    case dice
    case puzzle
    case arcade
    case strategy
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .cards: return "Epic Card Battle"
        case .candy: return "Candy Crush Adventure"
        case .dice: return "Dice Master Pro"
        case .puzzle: return "Brain Teaser Plus"
        case .arcade: return "Retro Arcade Classic"
        case .strategy: return "Strategic Conquest"
        }
    }
    
    var description: String {
        switch self {
        case .cards: return "Engaging multiplayer card game with advanced AI opponents"
        case .candy: return "Match-3 puzzle with power-ups and special combinations"
        case .dice: return "Strategic dice rolling with multipliers and bonuses"
        case .puzzle: return "Challenge your mind with increasingly difficult puzzles"
        case .arcade: return "Classic arcade games with modern twists"
        case .strategy: return "Build your empire in this turn-based strategy game"
        }
    }
}

// MARK: - GamesView
struct GamesView: View {
    @StateObject private var viewModel: GamesViewModel = GamesViewModel()
    @State private var selectedGame: GameType?
    @State private var showLeaderboard: Bool = false
    @State private var showAchievements: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Featured Game
                        if let featured = viewModel.featuredGame {
                            FeaturedGameView(game: featured)
                                .padding(.horizontal)
                        }
                        
                        // Game Categories
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(GameType.allCases) { game in
                                GameCardView(game: game) {
                                    selectedGame = game
                                    viewModel.trackGameSelection(game)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .navigationTitle("Game Center")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showLeaderboard = true }) {
                            Label("Leaderboard", systemImage: "list.number")
                        }
                        
                        Button(action: { showAchievements = true }) {
                            Label("Achievements", systemImage: "star.fill")
                        }
                        
                        Button(action: viewModel.refreshGames) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $selectedGame) { game in
                GameDetailView(game: game)
            }
            .sheet(isPresented: $showLeaderboard) {
                LeaderboardView()
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
            }
        }
        .environmentObject(viewModel)
    }
}

// MARK: - Featured Game View
struct FeaturedGameView: View {
    let game: GameType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Game")
                .font(.headline)
                .foregroundColor(.gray)
            
            ZStack(alignment: .bottomLeading) {
                Image("game_banner_\(game.rawValue)")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(game.description)
                        .font(.subheadline)
                        .lineLimit(2)
                }
                .padding()
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                )
            }
        }
    }
}

// MARK: - Game Card View
struct GameCardView: View {
    let game: GameType
    let action: () -> Void
    
    @EnvironmentObject private var viewModel: GamesViewModel
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image("game_thumb_\(game.rawValue)")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                    
                    if viewModel.isNewGame(game) {
                        Text("NEW")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(8)
                            .padding(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.title)
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", viewModel.rating(for: game)))
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(viewModel.playerCount(for: game)) playing")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Game Detail View
struct GameDetailView: View {
    let game: GameType
    @EnvironmentObject private var viewModel: GamesViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Game Banner
                    Image("game_banner_\(game.rawValue)")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Game Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(game.title)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(game.description)
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        
                        // Stats
                        HStack {
                            StatView(title: "Players", value: "\(viewModel.playerCount(for: game))")
                            StatView(title: "Rating", value: String(format: "%.1f", viewModel.rating(for: game)))
                            StatView(title: "Level", value: "\(viewModel.playerLevel(for: game))")
                        }
                        .padding(.horizontal)
                        
                        // Achievement Progress
                        AchievementProgressView(progress: viewModel.achievementProgress(for: game))
                            .padding(.horizontal)
                        
                        // Game Modes
                        GameModesView(modes: viewModel.gameModes(for: game))
                            .padding(.horizontal)
                        
                        // Play Button
                        Button(action: {
                            viewModel.startGame(game)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Play Now")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(15)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.toggleFavorite(game)
                    }) {
                        Image(systemName: viewModel.isFavorite(game) ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.isFavorite(game) ? .red : .gray)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AchievementProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Achievements")
                .font(.headline)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            Text("\(Int(progress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct GameModesView: View {
    let modes: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Game Modes")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(modes, id: \.self) { mode in
                        Text(mode)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

// MARK: - View Model
class GamesViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var featuredGame: GameType?
    private var gameStats: [GameType: GameStats] = [:]
    private let adAlgorithm = GameAdvertisingAlgorithm()
    
    init() {
        loadGames()
    }
    
    func loadGames() {
        isLoading = true
        // Simulate loading game data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.initializeGameStats()
            self.featuredGame = self.determineFeaturedGame()
            self.isLoading = false
        }
    }
    
    func refreshGames() {
        loadGames()
    }
    
    func trackGameSelection(_ game: GameType) {
        let behavior = UserBehavior(
            averagePlayTime: 300,
            gameCompletionRate: 0.75,
            interactionRate: 0.85,
            preferredGames: [game.rawValue],
            playHistory: []
        )
        
        let placement = adAlgorithm.determineOptimalAdPlacement(
            for: game.rawValue,
            userBehavior: behavior
        )
        
        // Use the ad placement to update the UI
        updateAdPlacement(placement)
    }
    
    func rating(for game: GameType) -> Double {
        return gameStats[game]?.rating ?? 4.0
    }
    
    func playerCount(for game: GameType) -> Int {
        return gameStats[game]?.playerCount ?? 0
    }
    
    func playerLevel(for game: GameType) -> Int {
        return gameStats[game]?.playerLevel ?? 1
    }
    
    func achievementProgress(for game: GameType) -> Double {
        return gameStats[game]?.achievementProgress ?? 0.0
    }
    
    func gameModes(for game: GameType) -> [String] {
        return gameStats[game]?.modes ?? []
    }
    
    func isNewGame(_ game: GameType) -> Bool {
        return gameStats[game]?.isNew ?? false
    }
    
    func isFavorite(_ game: GameType) -> Bool {
        return gameStats[game]?.isFavorite ?? false
    }
    
    func toggleFavorite(_ game: GameType) {
        if var stats = gameStats[game] {
            stats.isFavorite.toggle()
            gameStats[game] = stats
            objectWillChange.send()
        }
    }
    
    func startGame(_ game: GameType) {
        // Implement game start logic
    }
    
    private func initializeGameStats() {
        for game in GameType.allCases {
            gameStats[game] = GameStats(
                rating: Double.random(in: 4.0...5.0),
                playerCount: Int.random(in: 100...10000),
                playerLevel: Int.random(in: 1...50),
                achievementProgress: Double.random(in: 0...1),
                modes: generateGameModes(for: game),
                isNew: Bool.random(),
                isFavorite: false
            )
        }
    }
    
    private func determineFeaturedGame() -> GameType {
        return GameType.allCases.randomElement() ?? .cards
    }
    
    private func generateGameModes(for game: GameType) -> [String] {
        switch game {
        case .cards:
            return ["Single Player", "Multiplayer", "Tournament", "Practice"]
        case .candy:
            return ["Classic", "Time Attack", "Puzzle Mode", "Daily Challenge"]
        case .dice:
            return ["Classic", "Strategy", "Multiplayer", "Championship"]
        case .puzzle:
            return ["Story Mode", "Challenge", "Speed Run", "Zen Mode"]
        case .arcade:
            return ["Classic", "Modern", "Endless", "Time Attack"]
        case .strategy:
            return ["Campaign", "Skirmish", "Online Battle", "Custom Games"]
        }
    }
    
    private func updateAdPlacement(_ placement: AdPlacement) {
        // Implement ad placement update logic
    }
}

// MARK: - Supporting Types
struct GameStats {
    var rating: Double
    var playerCount: Int
    var playerLevel: Int
    var achievementProgress: Double
    var modes: [String]
    var isNew: Bool
    var isFavorite: Bool
}
