//
//  GamesView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-07.
//

import SwiftUI

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

struct GamesView: View {
    @State private var selectedGame: GameType?
    
    let games: [GameType] = [.cards, .candy, .dice]
    
    var body: some View {
        VStack {
            Text("Games View")
                .font(.headline)
            ForEach(games) { game in
                Button(action: {
                    selectedGame = game
                }) {
                    Text(game.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .sheet(item: $selectedGame) { game in
                switch game {
                case .cards:
                    CardsGameView()
                case .candy:
                    CandyGameView()
                case .dice:
                    DiceGameView()
                }
            }
        }
        .padding()
    }
}

struct CardsGameView: View {
    @State private var cards: [Card] = Card.generateDeck()
    @State private var score: Int = 0
    
    var body: some View {
        VStack {
            Text("Cards Game")
                .font(.headline)
            Spacer()
            Text("Score: \(score)")
                .font(.title)
            Spacer()
            HStack {
                ForEach(cards) { card in
                    Button(action: {
                        flipCard(card)
                    }) {
                        CardView(card: card)
                            .frame(width: 80, height: 120)
                    }
                }
            }
            Spacer()
            Button(action: {
                resetGame()
            }) {
                Text("Reset")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
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
    }
}

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

struct CandyGameView: View {
    @State private var candies: [Candy] = Candy.generateCandies()
    @State private var score: Int = 0
    
    var body: some View {
        VStack {
            Text("Candy Game")
                .font(.headline)
            Spacer()
            Text("Score: \(score)")
                .font(.title)
            Spacer()
            GridView(items: candies, columns: 4) { candy in
                CandyView(candy: candy)
                    .onTapGesture {
                        eatCandy(candy)
                    }
            }
            Spacer()
            Button(action: {
                resetGame()
            }) {
                Text("Reset")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func eatCandy(_ candy: Candy) {
        guard let candyIndex = candies.firstIndex(where: { $0.id == candy.id }) else { return }
        
        withAnimation {
            candies.remove(at: candyIndex)
        }
        
        score += candy.points
    }
    
    private func resetGame() {
        candies = Candy.generateCandies()
        score = 0
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
            Candy(name: "Gummy Bear", image: "gummybear", points: 7),
            Candy(name: "Caramel", image: "caramel", points: 6),
            Candy(name: "Jelly Bean", image: "jellybean", points: 4),
            Candy(name: "Licorice", image: "licorice", points: 3),
            Candy(name: "Sour Patch", image: "sourpatch", points: 9),
        ]
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

struct DiceGameView: View {
    @State private var diceValues: [Int] = [1, 1, 1, 1, 1]
    @State private var score: Int = 0
    
    var body: some View {
        VStack {
            Text("Dice Game")
                .font(.headline)
            Spacer()
            Text("Score: \(score)")
                .font(.title)
            Spacer()
            HStack {
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
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func rollDice() {
        diceValues = (1...5).map { _ in Int.random(in: 1...6) }
        
        score = diceValues.reduce(0, +)
    }
}

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
            LazyVGrid(columns: gridLayout, spacing: 16) {
                ForEach(items) { item in
                    content(item)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var gridLayout: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
    }
}

