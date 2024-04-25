//
//  GamesView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-07.
//


import SwiftUI
import Combine

// MARK: - GameType Enum

enum GameType: String, Identifiable {
    case cards
    case candy
    case dice
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .cards:
            return "Cards Game"
        case .candy:
            return "Candy Game"
        case .dice:
            return "Dice Game"
        }
    }
}

// MARK: - GamesView

struct GamesView: View {
    @State private var selectedGame: GameType?
    
    let games: [GameType] = [.cards, .candy, .dice]
    
    var body: some View {
        NavigationView {
            List(games) { game in
                NavigationLink(destination: gameView(for: game)) {
                    Text(game.title)
                }
            }
            .navigationBarTitle("Games")
        }
    }
    
    private func gameView(for game: GameType) -> some View {
        switch game {
        case .cards:
            return AnyView(CardsGameView())
        case .candy:
            return AnyView(CandyGameView())
        case .dice:
            return AnyView(DiceGameView())
        }
    }
}

// MARK: - CardsGameView

struct CardsGameView: View {
    @State private var cards: [Card] = Card.generateDeck()
    @State private var score: Int = 0
    @State private var isTimerRunning: Bool = false
    @State private var timeRemaining: Int = 60
    @State private var showAlert: Bool = false
    @State private var isShuffling: Bool = false // New state for shuffling animation
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Cards Game")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Spacer()
            
            Text("Score: \(score)")
                .font(.title)
            
            Spacer()
            
            TimerView(timeRemaining: timeRemaining)
            
            Spacer()
            
            if !isShuffling {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                    ForEach(cards) { card in
                        CardView(card: card)
                            .onTapGesture {
                                flipCard(card)
                            }
                            .aspectRatio(2/3, contentMode: .fit)
                    }
                }
                .padding()
            } else {
                Text("Shuffling...")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button(action: {
                resetGame()
            }) {
                Text("Reset")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .onReceive(timer) { _ in
            guard isTimerRunning else { return }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endGame()
            }
        }
        .onAppear {
            startGame()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Game Over"), message: Text("Your final score is \(score)"), dismissButton: .default(Text("Play Again"), action: resetGame))
        }
    }
    
    private func flipCard(_ card: Card) {
        guard let cardIndex = cards.firstIndex(where: { $0.id == card.id }) else { return }
        
        withAnimation {
            cards[cardIndex].isFaceUp.toggle()
        }
        
        if cards.filter({ $0.isFaceUp }).count == 2 {
            let faceUpCards = cards.filter({ $0.isFaceUp })
            
            if faceUpCards[0].value == faceUpCards[1].value {
                score += 2
                cards.removeAll { card in
                    faceUpCards.contains(where: { $0.id == card.id })
                }
            } else {
                score -= 1
            }
        }
    }
    
    private func resetGame() {
        cards = Card.generateDeck()
        score = 0
        startGame()
    }
    
    private func startGame() {
        isTimerRunning = true
        timeRemaining = 60
    }
    
    private func endGame() {
        isTimerRunning = false
        showAlert = true
    }
}

// MARK: - CandyGameView

struct CandyGameView: View {
    @State private var candies: [Candy] = Candy.generateCandies()
    @State private var score: Int = 0
    @State private var isTimerRunning: Bool = false
    @State private var timeRemaining: Int = 60
    @State private var showAlert: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Candy Game")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Spacer()
            
            Text("Score: \(score)")
                .font(.title)
            
            Spacer()
            
            TimerView(timeRemaining: timeRemaining)
            
            Spacer()
            
            GridView(items: candies, columns: 4) { candy in
                CandyView(candy: candy)
                    .onTapGesture {
                        eatCandy(candy)
                    }
            }
            .padding()
            
            Spacer()
            
            Button(action: {
                resetGame()
            }) {
                Text("Reset")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .onReceive(timer) { _ in
            guard isTimerRunning else { return }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endGame()
            }
        }
        .onAppear {
            startGame()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Game Over"), message: Text("Your final score is \(score)"), dismissButton: .default(Text("Play Again"), action: resetGame))
        }
    }
    
    private func eatCandy(_ candy: Candy) {
        guard let candyIndex = candies.firstIndex(where: { $0.id == candy.id }) else { return }
        
        candies.remove(at: candyIndex)
        
        score += candy.points
    }

    
    private func resetGame() {
        candies = Candy.generateCandies()
        score = 0
        startGame()
    }
    
    private func startGame() {
        isTimerRunning = true
        timeRemaining = 60
    }
    
    private func endGame() {
        isTimerRunning = false
        showAlert = true
    }
}

// MARK: - DiceGameView

struct DiceGameView: View {
    @State private var diceValues: [Int] = [1, 1, 1, 1, 1]
    @State private var score: Int = 0
    @State private var isTimerRunning: Bool = false
    @State private var timeRemaining: Int = 60
    @State private var showAlert: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Dice Game")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Spacer()
            
            Text("Score: \(score)")
                .font(.title)
            
            Spacer()
            
            TimerView(timeRemaining: timeRemaining)
            
            Spacer()
            
            HStack(spacing: 20) {
                ForEach(diceValues, id: \.self) { value in
                    Image(systemName: "die.face.\(value).fill")
                        .font(.system(size: 80))
                }
            }
            
            Spacer()
            
            Button(action: {
                rollDice()
            }) {
                Text("Roll Dice")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .onReceive(timer) { _ in
            guard isTimerRunning else { return }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endGame()
            }
        }
        .onAppear {
            startGame()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Game Over"), message: Text("Your final score is \(score)"), dismissButton: .default(Text("Play Again"), action: resetGame))
        }
    }
    
    private func rollDice() {
        diceValues = (1...5).map { _ in Int.random(in: 1...6) }
        
        score = diceValues.reduce(0, +)
    }
    
    private func startGame() {
        isTimerRunning = true
        timeRemaining = 60
    }
    
    private func resetGame() {
        score = 0
        startGame()
    }
    
    private func endGame() {
        isTimerRunning = false
        showAlert = true
    }
}

// MARK: - TimerView

struct TimerView: View {
    let timeRemaining: Int
    
    var body: some View {
        Text("Time: \(timeRemaining)")
            .font(.headline)
            .padding()
            .background(Color.gray)
            .cornerRadius(10)
            .foregroundColor(.white)
    }
}

// MARK: - Grid View Component

struct GridView<Item, Content>: View where Item: Identifiable, Content: View {
    private let items: [Item]
    private let columns: Int
    private let content: (Item) -> Content
    
    init(items: [Item], columns: Int, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.columns = columns
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 10) {
                ForEach(items) { item in
                    content(item)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Model

struct Card: Identifiable {
    let id = UUID()
    var isFaceUp = false
    var value: String
    
    static func generateDeck() -> [Card] {
        var deck: [Card] = []
        
        let values = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
        
        for value in values {
            deck.append(Card(value: value))
            deck.append(Card(value: value))
        }
        
        return deck.shuffled()
    }
}

struct Candy: Identifiable {
    let id = UUID()
    let name: String
    let image: String
    let points: Int
    
    static func generateCandies() -> [Candy] {
        return [
            Candy(name: "Chocolate Bar", image: "chocolate", points: 10),
            Candy(name: "Candy Cane", image: "candycane", points: 5),
            Candy(name: "Lollipop", image: "lollipop", points: 8),
            // Add more candy types here
        ]
    }
}

struct CardView: View {
    let card: Card
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
            RoundedRectangle(cornerRadius: 10)
                .stroke(lineWidth: 2)
            
            if card.isFaceUp {
                Text(card.value)
                    .font(.title)
                    .fontWeight(.bold)
            } else {
                Image(systemName: "questionmark")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct CandyView: View {
    let candy: Candy
    
    var body: some View {
        VStack {
            Image(candy.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
            Text(candy.name)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

// MARK: - App


struct GameApp: App {
    var body: some Scene {
        WindowGroup {
            GamesView()
        }
    }
}
