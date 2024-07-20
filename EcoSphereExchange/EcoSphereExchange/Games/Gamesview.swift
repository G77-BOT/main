//
//  GamesView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-07.
//


import SwiftUI

// MARK: - GameType Enum

enum GameType: String, Identifiable, CaseIterable {
    case cards
    case candy
    case dice
    case ludo
    
    var id: String { self.rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .cards:
            return "Cards Game"
        case .candy:
            return "Candy Game"
        case .dice:
            return "Dice Game"
        case .ludo:
            return "Ludo Game"
        }
    }
    
    var icon: String {
        switch self {
        case .cards:
            return "suit.spade.fill"
        case .candy:
            return "bonbon.fill"
        case .dice:
            return "die.face.6.fill"
        case .ludo:
            return "gamecontroller.fill"
        }
    }
}

// MARK: - GameCellViewModel Protocol

protocol GameCellViewModel {
    var title: LocalizedStringKey { get }
    var icon: String { get }
}

extension GameType: GameCellViewModel {}

// MARK: - GameCell View

struct GameCell: View {
    let viewModel: GameCellViewModel

    var body: some View {
        VStack {
            Image(systemName: viewModel.icon)
               .resizable()
               .aspectRatio(contentMode: .fit)
               .frame(width: 50, height: 50)
               .foregroundColor(Color.blue)
               .padding(.bottom, 10)

            Text(viewModel.title)
               .font(.headline)
               .foregroundColor(Color.black)
               .multilineTextAlignment(.center)
        }
       .padding(20)
       .background(Color.white)
       .cornerRadius(20)
       .shadow(color: Color.gray.opacity(0.4), radius: 5, x: 0, y: 2)
    }
}

// MARK: - GamesView

struct GamesView: View {
    @State private var selectedGame: GameType?
    @State private var showAds = true
    
    let games: [GameType] = GameType.allCases
    
    var body: some View {
        NavigationView {
            GridView(items: games, columns: 2) { game in
                NavigationLink(destination: gameView(for: game)) {
                    GameCell(viewModel: game)
                }
            }
           .navigationBarTitle("Games")
        }
       .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func gameView(for game: GameType) -> some View {
        switch game {
        case .cards:
            return AnyView(CardsGameView())
        case .candy:
            return AnyView(CandyGameView())
        case .dice:
            return AnyView(DiceGameView())
        case .ludo:
            return AnyView(LudoGameView())
        }
    }
}

// MARK: - CardsGameView

struct CardsGameView: View {
    @StateObject private var viewModel = CardsGameViewModel()
    @State private var showAds = true

    var body: some View {
        VStack {
            Text("Cards Game")
               .font(.largeTitle)
               .fontWeight(.bold)
               .padding()

            Spacer()

            Text("Score: \(viewModel.score)")
               .font(.title)
               .padding()

            Spacer()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                ForEach(viewModel.cards) { card in
                    CardView(card: card)
                       .onTapGesture {
                            viewModel.flipCard(card)
                        }
                       .aspectRatio(2/3, contentMode:.fit)
                }
            }
           .padding()

            Spacer()

            Button(action: {
                viewModel.resetGame()
            }) {
                Text("Reset")
                   .font(.headline)
                   .foregroundColor(.white)
                   .padding()
                   .background(Color.blue)
                   .cornerRadius(8)
            }
           .padding()
        }
       .padding()
       .advertisingBanner(isShown: showAds)
    }
}

// MARK: - CandyGameView

struct CandyGameView: View {
    @StateObject private var viewModel = CandyGameViewModel()
    @State private var showAds = true

    var body: some View {
        VStack {
            Text("Candy Game")
               .font(.largeTitle)
               .fontWeight(.bold)
               .padding()

            Spacer()

            Text("Score: \(viewModel.score)")
               .font(.title)
               .padding()

            Spacer()

            GridView(items: viewModel.candies, columns: 4) { candy in
                CandyView(candy: candy)
                   .onTapGesture {
                        viewModel.eatCandy(candy)
                    }
            }
           .padding()

            Spacer()

            Button(action: {
                viewModel.resetGame()
            }) {
                Text("Reset")
                   .font(.headline)
                   .foregroundColor(.white)
                   .padding()
                   .background(Color.blue)
                   .cornerRadius(8)
            }
           .padding()
        }
       .padding()
       .advertisingBanner(isShown: showAds)
    }
}

// MARK: - DiceGameView

struct DiceGameView: View {
    @StateObject private var viewModel = DiceGameViewModel()
    @State private var showAds = true

    var body: some View {
        VStack {
            Text("Dice Game")
               .font(.largeTitle)
               .fontWeight(.bold)
               .padding()

            Spacer()

            Text("Score: \(viewModel.score)")
               .font(.title)
               .padding()

            Spacer()

            HStack(spacing: 20) {
                ForEach(viewModel.diceValues, id: \.self) { value in
                    Image(systemName: "die.face.\(value).fill")
                       .font(.system(size: 80))
                }
            }

            Spacer()

            Button(action: {
                viewModel.rollDice()
            }) {
                Text("Roll Dice")
                   .font(.headline)
                   .foregroundColor(.white)
                   .padding()
                   .background(Color.blue)
                   .cornerRadius(8)
            }

            Spacer()
        }
       .padding()
       .advertisingBanner(isShown: showAds)
    }
}

// MARK: - LudoGameView

struct LudoGameView: View {
    @StateObject private var viewModel = LudoGameViewModel()
    @State private var showAds = true
    @State private var membership = false

    var body: some View {
        VStack {
            Text("Ludo Game")
               .font(.largeTitle)
               .fontWeight(.bold)
               .padding()

            Spacer()

            Text("Current Turn: \(viewModel.currentPlayer.rawValue.capitalized)")
               .font(.title)
               .foregroundColor(viewModel.currentPlayer.color)

            Spacer()

            LudoBoardView(board: viewModel.board, onTapPosition: viewModel.moveToken)
               .padding()

            Spacer()

            TimerView(timeRemaining: viewModel.timeRemaining)

            Spacer()

            Button(action: {
                viewModel.resetGame()
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
       .advertisingBanner(isShown: showAds)
       .membershipAlert(isShown: !membership)
    }
}

// MARK: - MembershipAlert Modifier

extension View {
    func membershipAlert(isShown: Bool) -> some View {
        alert(isPresented: .constant(isShown)) {
            Alert(title: Text("Upgrade to Premium"),
                  message: Text("Join our premium membership to enjoy ad-free gaming experience and access exclusive games."),
                  primaryButton: .default(Text("Upgrade"), action: {
                      // Implement upgrade action
                  }),
                  secondaryButton: .cancel(Text("Not Now")))
        }
    }
}

// MARK: - AdvertisingBanner Modifier

extension View {
    func advertisingBanner(isShown: Bool) -> some View {
        ZStack(alignment: .bottom) {
            self
            if isShown {
                // Display advertisement here
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 50)
                    .overlay(Text("Advertisement").foregroundColor(.white))
            }
        }
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

// MARK: - Ludo Board View

struct LudoBoardView: View {
    let board: [[LudoCell]]
    let onTapPosition: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(board.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(board[rowIndex].indices, id: \.self) { columnIndex in
                        LudoCellView(cell: board[rowIndex][columnIndex])
                            .onTapGesture {
                                onTapPosition(rowIndex, columnIndex)
                            }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Ludo Cell View

struct LudoCellView: View {
    let cell: LudoCell
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(cell.color)
            Text(cell.title)
                .foregroundColor(.white)
                .font(.headline)
        }
        .frame(width: 50, height: 50)
        .border(Color.black)
    }
}

// MARK: - Ludo Game Model

class LudoGameViewModel: ObservableObject {
    @Published var board: [[LudoCell]]
    @Published var currentPlayer: Player
    @Published var timeRemaining: Int
    @Published var showAlert: Bool = false
    @Published var winner: Player? = nil
    @Published var showAds = true
    @Published var membership = false
    
    private var timer: Timer?
    private var remainingMoves: Int = 60
    
    init() {
        self.board = Array(repeating: Array(repeating: .empty, count: 4), count: 4)
        self.currentPlayer = .red
        self.timeRemaining = 60
        self.setupBoard()
        self.startTimer()
    }
    
    private func setupBoard() {
        // Set initial positions for tokens
        board[0][0] = .token(.red)
        board[3][0] = .token(.green)
        board[3][3] = .token(.blue)
        board[0][3] = .token(.yellow)
    }
    
    func moveToken(row: Int, column: Int) {
        guard case let .token(player) = board[row][column], player == currentPlayer else { return }
        
        // Implement movement logic here
        
        // Example: Move the token one step ahead
        board[row][column] = .empty
        let newRow = (row + 1) % 4
        board[newRow][column] = .token(player)
        
        nextPlayer()
    }
    
    private func nextPlayer() {
        switch currentPlayer {
        case .red:
            currentPlayer = .green
        case .green:
            currentPlayer = .blue
        case .blue:
            currentPlayer = .yellow
        case .yellow:
            currentPlayer = .red
        }
    }
    
    func resetGame() {
        timeRemaining = 60
        remainingMoves = 60
        setupBoard()
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingMoves -= 1
            if self.remainingMoves <= 0 {
                self.endGame()
            }
        }
    }
    
    private func endGame() {
        timer?.invalidate()
        showAlert = true
        winner = currentPlayer
    }
}

// MARK: - Ludo Cell

enum LudoCell: Hashable {
    case empty
    case token(Player)
    
    var color: Color {
        switch self {
        case .empty:
            return .white
        case .token(let player):
            return player.color
        }
    }
    
    var title: String {
        switch self {
        case .empty:
            return ""
        case .token(let player):
            return player.rawValue.uppercased()
        }
    }
    
    var isToken: Bool {
        if case .token = self {
            return true
        }
        return false
    }
}

// MARK: - Player

enum Player: String {
    case red
    case green
    case blue
    case yellow
    
    var color: Color {
        switch self {
        case .red:
            return .red
        case .green:
            return .green
        case .blue:
            return .blue
        case .yellow:
            return .yellow
        }
    }
}

// MARK: - Candy Game Model

class CandyGameViewModel: ObservableObject {
    @Published var candies: [Candy]
    @Published var score: Int = 0
    
    init() {
        self.candies = Candy.generateCandies()
    }
    
    func eatCandy(_ candy: Candy) {
        score += candy.points
        candies.removeAll { $0.id == candy.id }
    }
    
    func resetGame() {
        score = 0
        candies = Candy.generateCandies()
    }
}

// MARK: - Dice Game Model

class DiceGameViewModel: ObservableObject {
    @Published var diceValues: [Int] = []
    @Published var score: Int = 0
    
    func rollDice() {
        diceValues = (1...6).map { _ in Int.random(in: 1...6) }
        score += diceValues.reduce(0, +)
    }
}

// MARK: - Cards Game Model

class CardsGameViewModel: ObservableObject {
    @Published var cards: [Card]
    @Published var score: Int = 0
    
    init() {
        self.cards = Card.generateDeck()
    }
    
    func flipCard(_ card: Card) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            if !cards[index].isFaceUp {
                score += 1
                cards[index].isFaceUp = true
            }
        }
    }
    
    func resetGame() {
        score = 0
        cards = Card.generateDeck()
    }
}

// MARK: - GameViewController

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGameView()
    }
    
    func setupGameView() {
        let gamesView = GamesView()
            .edgesIgnoringSafeArea(.all)
        
        let hostingController = UIHostingController(rootView: gamesView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
