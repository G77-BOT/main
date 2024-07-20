//
//  CandyGameView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-05-08.
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

class CandyGameView: UIView {
    var backgroundMusic: AVAudioPlayer?
    var candyCrushSound: AVAudioPlayer?
    
    var candies: [[String]] = []
    var score: Int = 0
    let numRows = 8
    let numCols = 8
    let candySize: CGFloat = 40.0
    let candyTypes = ["CandyCane", "Lollipop", "ChocolateBar", "GummyBear", "SpecialCandy"]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGame()
        loadSounds()
        playBackgroundMusic()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGame()
        loadSounds()
        playBackgroundMusic()
    }
    
    func setupGame() {
        backgroundColor = .white
        initializeCandies()
        setupCandyViews()
        print("The game is set up")
    }
    
    func initializeCandies() {
        for _ in 0..<numRows {
            var row: [String] = []
            for _ in 0..<numCols {
                let candy = randomCandy()
                row.append(candy)
            }
            candies.append(row)
        }
    }
    
    func randomCandy() -> String {
        return candyTypes.randomElement()!
    }
    
    func loadSounds() {
        if let backgroundURL = Bundle.main.url(forResource: "candyBackgroundMusic", withExtension: "mp3") {
            backgroundMusic = try? AVAudioPlayer(contentsOf: backgroundURL)
            backgroundMusic?.prepareToPlay()
            backgroundMusic?.numberOfLoops = -1
        }
        
        if let crushSoundURL = Bundle.main.url(forResource: "candyCrushSound", withExtension: "mp3") {
            candyCrushSound = try? AVAudioPlayer(contentsOf: crushSoundURL)
            candyCrushSound?.prepareToPlay()
        }
    }
    
    func playBackgroundMusic() {
        backgroundMusic?.play()
    }
    
    func setupCandyViews() {
        for row in 0..<numRows {
            for col in 0..<numCols {
                let candyView = createCandyView(row: row, col: col)
                addSubview(candyView)
            }
        }
    }
    
    func createCandyView(row: Int, col: Int) -> UIImageView {
        let candy = candies[row][col]
        let candyView = UIImageView(image: UIImage(named: candy))
        candyView.frame = CGRect(x: CGFloat(col) * candySize, y: CGFloat(row) * candySize, width: candySize, height: candySize)
        candyView.isUserInteractionEnabled = true
        candyView.tag = row * numCols + col
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCandyTap(_:)))
        candyView.addGestureRecognizer(tapGesture)
        return candyView
    }
    
    @objc func handleCandyTap(_ sender: UITapGestureRecognizer) {
        guard let candyView = sender.view as? UIImageView else { return }
        let tag = candyView.tag
        let row = tag / numCols
        let col = tag % numCols
        crushCandy(atRow: row, col: col)
    }
    
    func crushCandy(atRow row: Int, col: Int) {
        guard row >= 0 && row < numRows && col >= 0 && col < numCols else {
            print("Please select a valid candy.")
            return
        }
        
        let candy = candies[row][col]
        print("Candy \(candy) crushed!")
        candyCrushSound?.play()
        score += 10
        if candy == "SpecialCandy" {
            score += 40 // Bonus points for special candy
        }
        candies[row][col] = ""
        updateScore()
        animateCrush(row: row, col: col)
        checkForMatches()
    }
    
    func animateCrush(row: Int, col: Int) {
        let tag = row * numCols + col
        if let candyView = viewWithTag(tag) as? UIImageView {
            UIView.animate(withDuration: 0.3, animations: {
                candyView.alpha = 0
            }, completion: { _ in
                candyView.removeFromSuperview()
                self.refillBoard()
            })
        }
    }
    
    func checkForMatches() {
        var matchedCandies: Set<[Int]> = []
        for row in 0..<numRows {
            for col in 0..<numCols {
                if let matches = findMatches(atRow: row, col: col) {
                    matchedCandies.formUnion(matches)
                }
            }
        }
        
        for match in matchedCandies {
            let row = match[0]
            let col = match[1]
            candies[row][col] = ""
        }
        
        if !matchedCandies.isEmpty {
            refillBoard()
        }
    }
    
    func findMatches(atRow row: Int, col: Int) -> Set<[Int]>? {
        let candy = candies[row][col]
        guard !candy.isEmpty else { return nil }
        
        var horizontalMatches: Set<[Int]> = []
        var verticalMatches: Set<[Int]> = []
        
        // Check horizontally
        var matchCount = 0
        for c in col..<numCols {
            if candies[row][c] == candy {
                matchCount += 1
                horizontalMatches.insert([row, c])
            } else {
                break
            }
        }
        
        if matchCount < 3 { horizontalMatches.removeAll() }
        
        // Check vertically
        matchCount = 0
        for r in row..<numRows {
            if candies[r][col] == candy {
                matchCount += 1
                verticalMatches.insert([r, col])
            } else {
                break
            }
        }
        
        if matchCount < 3 { verticalMatches.removeAll() }
        
        let matches = horizontalMatches.union(verticalMatches)
        return matches.isEmpty ? nil : matches
    }
    
    func refillBoard() {
        for row in (0..<numRows).reversed() {
            for col in 0..<numCols {
                if candies[row][col].isEmpty {
                    for r in (0...row).reversed() {
                        if !candies[r][col].isEmpty {
                            candies[row][col] = candies[r][col]
                            candies[r][col] = ""
                            break
                        }
                    }
                    if candies[row][col].isEmpty {
                        candies[row][col] = randomCandy()
                    }
                    let candyView = createCandyView(row: row, col: col)
                    addSubview(candyView)
                }
            }
        }
    }
    
    func updateScore() {
        print("Score: \(score)")
    }
    
    func resetGame() {
        score = 0
        candies.removeAll()
        initializeCandies()
        setupCandyViews()
        print("Game reset")
        updateScore()
    }
    
    func displayCandies() {
        for row in candies {
            print(row)
        }
    }
}

// Advanced game logic and interaction
class CandyGameViewController: UIViewController {
    var gameView: CandyGameView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGameView()
    }
    
    func setupGameView() {
        gameView = CandyGameView(frame: view.bounds)
        view.addSubview(gameView)
    }
    
    func handleCandySelection(atRow row: Int, col: Int) {
        gameView.crushCandy(atRow: row, col: col)
    }
}

// Usage in a typical app context
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = CandyGameViewController()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        return true
    }
}