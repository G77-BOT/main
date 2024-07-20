//
//  CardsGameView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-05-08.
//

import UIKit
import AVFoundation

struct Card {
    var suit: String
    var rank: String
    
    var description: String {
        return "\(rank) of \(suit)"
    }
    
    var isSpecial: Bool {
        return rank == "Joker"
    }
}

enum GameType {
    case poker
    case blackjack
    case joker
    case `default`
}

class CasinoTable {
    var type: GameType
    
    init(type: GameType) {
        self.type = type
    }
}

class CardsGameView: UIView {
    // Declare properties for game state, audio players, etc.
    var cardAudio: AVAudioPlayer?
    var gameType: GameType = .poker
    var numberOfCards: Int = 52
    var cards: [Card] = []
    var tables: [CasinoTable] = []
    var selectedCards: [Card] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadAudio()
        setupGame()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadAudio()
        setupGame()
    }
    
    func loadAudio() {
        // Load audio files for card game events
        if let cardSound = Bundle.main.url(forResource: "cardFlipSound", withExtension: "mp3") {
            cardAudio = try? AVAudioPlayer(contentsOf: cardSound)
            cardAudio?.prepareToPlay()
        }
    }
    
    func playCardSound() {
        // Play card flip sound
        cardAudio?.play()
    }
    
    func setupGame() {
        // Initialize game setup based on game type
        switch gameType {
        case .poker:
            setupPokerGame()
        case .blackjack:
            setupBlackjackGame()
        case .joker:
            setupJokerGame()
        default:
            setupDefaultGame()
        }
    }
    
    func setupPokerGame() {
        // Setup logic for Poker game
        print("Setting up Poker game...")
        // Initialize poker-specific tables and cards
        tables = [CasinoTable(type: .poker)]
        cards = generateDeck()
        shuffleCards()
    }
    
    func setupBlackjackGame() {
        // Setup logic for Blackjack game
        print("Setting up Blackjack game...")
        // Initialize blackjack-specific tables and cards
        tables = [CasinoTable(type: .blackjack)]
        cards = generateDeck()
        shuffleCards()
    }
    
    func setupJokerGame() {
        // Setup logic for Joker game
        print("Setting up Joker game...")
        // Initialize joker-specific tables and cards
        tables = [CasinoTable(type: .joker)]
        cards = generateDeck(includeJokers: true)
        shuffleCards()
    }
    
    func setupDefaultGame() {
        // Setup logic for default card game
        print("Setting up default card game...")
        // Initialize default tables and cards
        tables = [CasinoTable(type: .default)]
        cards = generateDeck()
        shuffleCards()
    }
    
    func generateDeck(includeJokers: Bool = false) -> [Card] {
        // Generate a standard deck of cards, optionally including jokers
        var deck: [Card] = []
        let suits = ["Hearts", "Diamonds", "Clubs", "Spades"]
        let ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
        
        for suit in suits {
            for rank in ranks {
                deck.append(Card(suit: suit, rank: rank))
            }
        }
        
        if includeJokers {
            deck.append(Card(suit: "Joker", rank: "Joker"))
            deck.append(Card(suit: "Joker", rank: "Joker"))
        }
        
        return deck
    }
    
    func selectCard(at index: Int) {
        guard index >= 0 && index < cards.count else {
            print("Please select a valid card.")
            return
        }
        // Logic for selecting a card
        let card = cards[index]
        selectedCards.append(card)
        print("Card \(index) has been selected: \(card.description)")
        playCardSound()
        if card.isSpecial {
            handleSpecialCard(card)
        }
    }
    
    func handleSpecialCard(_ card: Card) {
        print("Special card selected: \(card.description)")
        // Additional logic for special cards
    }
    
    func shuffleCards() {
        print("Shuffling cards...")
        // Logic for shuffling cards
        cards.shuffle()
        playCardSound()
    }
    
    func resetGame() {
        print("Resetting the game...")
        // Logic for resetting the game
        setupGame()
    }
    
    func displayCards() {
        print("Displaying cards...")
        // Logic for displaying cards
        for card in cards {
            print(card.description)
        }
    }
}

// Base class for card games
class CardGame {
    var deck: Deck
    var players: [[Card]]
    var numberOfPlayers: Int
    
    init(numberOfPlayers: Int) {
        self.numberOfPlayers = numberOfPlayers
        self.deck = Deck()
        self.players = Array(repeating: [], count: numberOfPlayers)
        dealInitialCards()
    }
    
    func dealInitialCards() {
        for _ in 0..<5 {
            for player in 0..<numberOfPlayers {
                if let card = deck.deal() {
                    players[player].append(card)
                }
            }
        }
    }
    
    func displayHands() {
        for (playerIndex, hand) in players.enumerated() {
            print("Player \(playerIndex + 1)'s hand: \(hand.map { $0.description }.joined(separator: ", "))")
        }
    }
}

// Poker game class
class PokerGame: CardGame {
    override func dealInitialCards() {
        for _ in 0..<2 {
            for player in 0..<numberOfPlayers {
                if let card = deck.deal() {
                    players[player].append(card)
                }
            }
        }
    }
    
    func play() {
        print("Playing Poker...")
        displayHands()
    }
}

// Blackjack game class
class BlackjackGame: CardGame {
    override func dealInitialCards() {
        for _ in 0..<2 {
            for player in 0..<numberOfPlayers {
                if let card = deck.deal() {
                    players[player].append(card)
                }
            }
        }
    }
    
    func play() {
        print("Playing Blackjack...")
        displayHands()
    }
}

// Deck management
class Deck {
    var cards: [Card]
    
    init() {
        cards = []
        let suits = ["Hearts", "Diamonds", "Clubs", "Spades"]
        let ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
        
        for suit in suits {
            for rank in ranks {
                cards.append(Card(suit: suit, rank: rank))
            }
        }
        shuffle()
    }
    
    func shuffle() {
        cards.shuffle()
    }
    
    func deal() -> Card? {
        return cards.isEmpty ? nil : cards.removeFirst()
    }
}

// Usage in a typical app context
class CasinoGameViewController: UIViewController {
    var gameView: CardsGameView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGameView()
        
        let pokerGame = PokerGame(numberOfPlayers: 4)
        pokerGame.play()
        
        let blackjackGame = BlackjackGame(numberOfPlayers: 4)
        blackjackGame.play()
    }
    
    func setupGameView() {
        gameView = CardsGameView(frame: view.bounds)
        view.addSubview(gameView)
    }
}

// Usage in the app delegate
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = CasinoGameViewController()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        return true
    }
}


